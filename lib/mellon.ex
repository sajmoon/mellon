defmodule Mellon do
  import Plug.Conn
  alias Plug.Conn

  @default_parameters [header: "Authorization"]

  @behaviour Plug
  def init(params) do
    Keyword.get(params, :validator) || raise_missing_argument

    Keyword.merge(@default_parameters, params)
  end
  def init, do: raise_missing_argument

  def call(conn, params) do
    conn
    |> authenticate_request!(params)
  end

  defp raise_missing_argument do
    raise ArgumentError, "Requires some argment. See doc"
  end

  defp authenticate_request!(conn, validator: authentication_method, header: header_text) do
    conn
    |> parse_header(header_text)
    |> decode_token
    |> assert_token(authentication_method)
    |> handle_validation
  end

  defp parse_header(conn, header) do
    {conn, Conn.get_req_header(conn, header)}
  end

  defp decode_token({conn, []}), do: {conn, nil}
  defp decode_token({conn, ["Token: " <> encoded_token | _]}) do
    {conn, encoded_token}
  end
  defp decode_token({conn, [_token]}), do: {conn, nil}

  defp assert_token({conn, nil}, params) do
    assert_token({conn, ""}, params)
  end
  defp assert_token({conn, val}, {module, function, _args}) do
    apply(module, function, [{conn, val}])
  end

  defp handle_validation({:ok, cargo, conn}) do
    conn
    |> assign(:credentials, cargo)
  end
  defp handle_validation({:error, conn}) do
    deny(conn)
  end

  defp deny(conn) do
    conn
    |> send_resp(401, "Unauthorized")
    |> halt
  end
end

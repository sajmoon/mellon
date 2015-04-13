defmodule Mellon do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug
  def init(params), do: params

  def call(conn, params) do
    register_before_send(conn, &authenticate_request!(&1, params))
  end

  defmodule InvalidTokenError do
    defexception message: "Unauthorized", plug_status: 403
  end

  defp authenticate_request!(conn, {authentication_method, header_text}) do
    conn
    |> parse_header(header_text)
    |> decode_token
    |> assert_token(authentication_method)
    |> handle_validation
  end

  defp parse_header(conn, header) do
    {conn, Conn.get_req_header(conn, header)}
  end

  defp decode_token({conn, []}) do
    {conn, nil}
  end

  defp decode_token({conn, ["Token: " <> encoded_token | _]}) do
    {conn, encoded_token}
  end

  defp assert_token({conn, nil}, params) do
    assert_token({conn, ""}, params)
  end

  defp assert_token({conn, val}, {module, function, args}) do
    apply(module, function, [{conn, val}])
  end

  defp handle_validation({:ok, cargo, conn}) do
    conn
    |> Conn.assign(:credentials, cargo)
  end

  defp handle_validation({:error, conn}) do
    deny(conn)
  end

  defp deny(conn) do
    raise InvalidTokenError
  end
end

defmodule Mellon do
  alias Plug.Conn

  def init(params) do
    params
  end

  def call(conn, params) do
    conn
    |> parse_header
    |> decode_token
    |> assert_token(params)
    |> handle_validation
  end

  defp handle_validation({:ok, conn} ) do
    conn
    |> Conn.assign(:credentials, {"simon", "pass"})
    conn
  end

  defp handle_validation({:error, conn}) do
    deny(conn)
  end

  defp parse_header(conn) do
    {conn, Conn.get_req_header(conn, "Authorization")}
  end

  defp decode_token({conn, []}) do
    {conn, nil}
  end

  defp decode_token({conn, ["Token: " <> encoded_token | _]}) do
    case Base.decode64(encoded_token) do
      {:ok, token} -> {conn, token}
      :error -> {conn, nil}
    end
  end

  defp assert_token({conn, nil}, _params) do
    {:error, conn}
  end

  defp assert_token({conn, val}, {module, function, args}) do
    apply(module, function, [{conn, val}])
  end

  defp deny(conn) do
    conn
    |> Conn.send_resp(401, "HTTP Authentication: Access Denied")
    |> Conn.halt
  end
end

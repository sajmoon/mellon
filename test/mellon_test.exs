defmodule MellonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule TestPlug do
    import Plug.Conn
    use Plug.Builder

    plug Mellon, {TestPlug, :validate, []}

    plug :index

    def validate({conn, val}) do
      case val do
        "VALIDTOKEN" -> {:ok, conn}
        _ -> {:error, conn}
      end
    end

    defp index(conn, _opts) do
      assign(conn, :logged_in, true)
      |> send_resp(200, "Herro")
    end
  end

  defp assert_unauthorized(conn) do
    assert conn.status == 401
    refute conn.assigns[:logged_in]
  end

  defp assert_authorized(conn) do
    assert conn.status == 200
    assert conn.assigns[:logged_in]
  end

  defp call(plug, []) do
    conn(:get, "/test/auth")
    |> plug.call([])
  end

  defp call(plug, [{header_key, header_value}]) do
    conn(:get, "/test/auth")
    |> put_req_header(header_key, header_value)
    |> plug.call([])
  end

  defp auth_header(token) do
    {"Authorization", "Token: " <> Base.encode64(token)}
  end

  test "test without credentials" do
    conn = call(TestPlug, [])
    assert_unauthorized conn
  end

  test "test with false credentials" do
    conn = call(TestPlug, [auth_header("RANDOMTOKEN")])
    assert_unauthorized conn
  end

  test "test with correct credentials" do
    conn = call(TestPlug, [auth_header("VALIDTOKEN")])
    assert_authorized  conn
  end
end

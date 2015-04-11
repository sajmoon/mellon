defmodule MellonTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule TestPlug do
    import Plug.Conn
    use Plug.Builder

    plug Mellon, {{TestPlug, :validate, []}, "authorization"}

    plug :index

    def validate({conn, val}) do
      case val do
        "VALIDTOKEN" -> {:ok, {"123456"}, conn}
        _ -> {:error, conn}
      end
    end

    defp index(conn, _opts) do
      assign(conn, :logged_in, true)
      |> send_resp(200, "Secure area")
    end
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
    {"authorization", "Token: " <> token}
  end

  test "test without credentials" do
    assert_raise Mellon.InvalidTokenError, fn ->
      call(TestPlug, [])
    end
  end

  test "test with false credentials" do
    assert_raise Mellon.InvalidTokenError, fn ->
      call(TestPlug, [auth_header("RANDOMTOKEN")])
    end
  end

  test "test with correct credentials" do
    conn = call(TestPlug, [auth_header("VALIDTOKEN")])

    refute conn.halted
    assert conn.status == 200
    assert conn.resp_body == "Secure area"
  end

  test "valid token, sets credentials" do
    conn = call(TestPlug, [auth_header("VALIDTOKEN")])

    assert conn.assigns[:credentials] == {"123456"}
  end
end

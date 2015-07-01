defmodule MellonTest do
  use ExUnit.Case, async: true
  doctest Mellon

  use Plug.Test

  defmodule TestPlug do
    import Plug.Conn
    use Plug.Builder

    plug Mellon, validator: {TestPlug, :validate, []}, header: "authorization"
    plug :index

    def validate({conn, val}) do
      case val do
        "VALIDTOKEN" -> {:ok, {"123456"}, conn}
        _ -> {:error, [], conn}
      end
    end

    defp index(conn, _opts) do
      send_resp(conn, 200, "Secure area")
    end
  end

  defmodule CustomErrorResponsePlug do
    import Plug.Conn
    use Plug.Builder

    plug Mellon, validator: {CustomErrorResponsePlug, :validate, []}

    def validate({conn, _val}) do
      {:error, [status: 403, message: "Nope not here"], conn}
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

  test "missing argument" do
    assert_raise ArgumentError, fn ->
      Mellon.init()
    end

    assert_raise ArgumentError, fn ->
      Mellon.init(header: "authorization")
    end
  end

  test "initalizer uses default values" do
    params = Mellon.init(validator: {TestPlug, :validate, []})

    assert Keyword.get(params, :header) == "Authorization"
  end

  test "initalizer does not overrider params with defualts" do
    params = Mellon.init(validator: {TestPlug, :validate, []}, header: "XAUTH")

    assert Keyword.get(params, :header) == "XAUTH"
  end

  test "unauthorized without credentials" do
    conn = call(TestPlug, [])

    assert conn.status == 401
    %{"error" => message} = conn.resp_body
    |> Poison.Parser.parse!
    assert message == "Unauthorized"
  end

  test "unauthorized with wrong credentials" do
    conn = call(TestPlug, [auth_header("RANDOMTOKEN")])
    assert conn.status == 401
  end

  test "authorized with correct credentials" do
    conn = call(TestPlug, [auth_header("VALIDTOKEN")])

    refute conn.halted
    assert conn.status == 200
    assert conn.resp_body == "Secure area"
  end

  test "unauthorized for wrong header" do
    conn = call(TestPlug, [{"WRONGHEADER", "Token: VALIDTOKEN"}])

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body != "Secure area"
  end

  test "unauthorized with wrong token format" do
    conn = call(TestPlug, [{"authorization", "Bearer VALIDTOKEN"}])

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body != "Secure area"
  end

  test "valid token, sets credentials" do
    conn = call(TestPlug, [auth_header("VALIDTOKEN")])

    assert conn.assigns[:credentials] == {"123456"}
    assert conn.resp_body == "Secure area"
    assert conn.status == 200
  end

  test "test custom error status and message" do
    conn = call(CustomErrorResponsePlug, [auth_header("VALIDTOKEN")])

    assert conn.state == :sent
    assert conn.status == 403
    %{"error" => message} = conn.resp_body
    |> Poison.Parser.parse!
    assert message == "Nope not here"
  end
end

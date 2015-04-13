defmodule SimpleappTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "/hello denied if no credentails" do
    conn = conn(:get, "/hello")
    assert_raise Mellon.InvalidTokenError, fn ->
      Simpleapp.call(conn, [])
    end
  end

  test "/hello ok if correct credentials" do
    conn = conn(:get, "/hello")
    |> put_req_header("X-AUTH", "Token: ValidToken")
    |> Simpleapp.call([])

    assert conn.state == :sent
    assert conn.status == 200
  end
end

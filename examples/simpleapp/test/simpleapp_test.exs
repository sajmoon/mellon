defmodule SimpleappTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "/hello denied if no credentails" do
    conn = conn(:get, "/hello")
    |> Simpleapp.call([])

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body != "Secure area"
  end

  test "denied if invalid token" do
    conn = conn(:get, "/hello")
    |> put_req_header("X-AUTH", "Token: InvalidToken")
    |> Simpleapp.call([])

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body != "Secure area"
  end

  test "denied if token form is wrong" do
    conn = conn(:get, "/hello")
    |> put_req_header("X-AUTH", "")
    |> Simpleapp.call([])

    assert conn.state == :sent
    assert conn.status == 401
    assert conn.resp_body != "Secure area"
  end

  test "/hello ok if correct credentials" do
    conn = conn(:get, "/hello")
    |> put_req_header("X-AUTH", "Token: ValidToken")
    |> Simpleapp.call([])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Secure area"
  end
end

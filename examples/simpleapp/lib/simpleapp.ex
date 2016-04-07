defmodule Simpleapp do
  use Plug.Router

  plug Mellon, validator: {Simpleapp, :authenticate, []}, header: "x-auth"

  plug :match
  plug :dispatch

  def authenticate({conn, token}) do
    case token do
      "ValidToken" -> {:ok, {}, conn}
      _ -> {:error, [], conn}
    end
  end

  get "/hello" do
    conn
    |> send_resp(200, "Secure area")
  end

  match _ do
    conn
    |> send_resp(404, "Not Found")
  end

  def start do
    Plug.Adapters.Cowboy.http Simpleapp, [], port: 4000
  end

  def stop do
    Plug.Adapters.Cowboy.shutdown Simpleapp.HTTP
  end
end

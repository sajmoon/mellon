Mellon
======

[![Build Status](https://travis-ci.org/sajmoon/mellon.svg?branch=master)](https://travis-ci.org/sajmoon/mellon)

An authentication module for Plug applications.

## Intallation
```elixir
defp deps do
  [{:mellon, github: "sajmoon/mellon"}]
end
```

## How to use

See /examples for a working example.

```elixir
defmodule MyApp do
  import Plug.Conn
  use Plug.Builder

  plug Mellon, validator: {MyApp, :validate, []}, header: "X-AUTH"

  plug :index

  def validate({conn, token}) do
    case token do
      "ValidToken" -> {:ok, {"userdata"}, conn}
      _ -> {:error, conn}
  end

  def index(conn, _opts) do
    send_resp(conn, 200, "Secure area")
  end
end
```

To authenticated for this example using curl you might do the following:

```bash
curl --header "X-AUTH: Token: ValidToken" localhost:4000/hello
```

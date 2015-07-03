Mellon
======

[![Build Status](https://travis-ci.org/sajmoon/mellon.svg?branch=master)](https://travis-ci.org/sajmoon/mellon)

An authentication module for Plug applications.

## Intallation
```elixir
defp deps do
  [{:mellon, "~> 0.0.1"}]
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
      _ -> {:error, [], conn}
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

## Configuration
You can configure some parameters while initializing Mellon.

**Required**

`validator`: The function that validates the token. Must return {:ok, userdata, conn} if valid and {:error, conn} if not.

**Optional**

`header`: The http header used for tokens. Will default to  'Authorization'.


## Return object from validator
The validator can return some options.

All requests that are authenticated should return
```
{:ok, cargo, conn}
```

cargo can be any object that you would like to pass along. it will be assigned to the request so you can access it later in your controller.
It will be assigned to `:credentials`. To access it later you could do the following: `conn.assigns[:credentials]`.

If authentication fails you should return `{:error, options, conn}`.

Where options is a `Keyword` containing `status:` and `message`.
Both are optional.

In case you want a custom Unauthenticated message include `[message: 'Get out of here!']`




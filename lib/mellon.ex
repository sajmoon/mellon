defmodule Mellon do
  @moduledoc """
  `Mellon` is a simple authentication plug.

  It can be used to any plug based service via headers.
  It is configurable, and easily exentable. Use it to parse requests,
  but it allows you to implement your own validation and authentication.

  ## Usage

  ## Parameters

  ### Mandatory
  * `validator` - defines the method to validate the token. Defined in the form {Module, :method, args}.
     example {SimpleApp, :authorization, []}

  ### Optional
  * `header` - the header name to use for the token. defaults to `"Authorization"`

  """

  import Plug.Conn
  alias Plug.Conn

  @default_parameters [header: "Authorization", block: true]
  @behaviour Plug

  @doc """
    Configure `Mellon`.

    Takes parameters in the form of [header: "value"]
    * `validator` - validaton function. {Module, :method, args}
    * `header` - http header. string.

    Error raised when requiered attributs are missing.

    ## Usage

    plug Mellon, validator: {MyApp, :auth, []}, header: "x-api"

    ## Example

      iex> Mellon.init validator: {TestApp, :authenticate, []}
      [validator: {TestApp, :authenticate, []}, header: "Authorization", block: true]

      iex> Mellon.init
      ** (ArgumentError) Missing some required arguments. See doc

      iex> Mellon.init header: "x-api"
      ** (ArgumentError) Missing some required arguments. See doc

  """
  def init(params) do
    ensure_required_param(params, :validator)

    Keyword.merge(@default_parameters, params)
  end
  def init, do: raise(ArgumentError, "Missing some required arguments. See doc")

  def call(conn, params) do
    conn
    |> authenticate_request!(params)
  end

  defp ensure_required_param(params, param) do
    Keyword.get(params, param) || raise ArgumentError, "Missing some required arguments. See doc"
  end

  defp authenticate_request!(conn, validator: authentication_method, header: header_text, block: block) do
    conn
    |> parse_header(header_text)
    |> decode_token
    |> assert_token(authentication_method)
    |> handle_validation(block)
  end

  defp parse_header(conn, header) do
    {conn, Conn.get_req_header(conn, header)}
  end

  defp decode_token({conn, []}), do: {conn, nil}
  defp decode_token({conn, ["Token: " <> encoded_token | _]}) do
    {conn, encoded_token}
  end
  defp decode_token({conn, [_token]}), do: {conn, nil}

  defp assert_token({conn, nil}, params) do
    assert_token({conn, ""}, params)
  end
  defp assert_token({conn, val}, {module, function, _args}) do
    apply(module, function, [{conn, val}])
  end

  defp handle_validation({:ok, cargo, conn}, _block) do
    conn
    |> assign(:credentials, cargo)
  end
  defp handle_validation({:error, option, conn}, true) do
    default = [status: 401, message: "Unauthorized"]
    option = Keyword.merge(default, option)

    deny(conn, option)
  end
  defp handle_validation({:error, _option, conn}, false) do
    # Do nothing. This allows non-blocking authentication.
    # If the user is authenticated, we assigns credentials
    # otherwise just let it pass through
    conn
  end

  defp deny(conn, [status: status, message: msg]) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(%{error: msg}))
    |> halt
  end
end

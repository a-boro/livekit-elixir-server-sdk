defmodule ExLivekit.Client.HTTPClient do
  @moduledoc """
  Behaviour for HTTP client implementations.

  This module defines the contract that HTTP client implementations must follow
  to be used with `ExLivekit.Client`. Implementations should provide:

  - `child_spec/0` - Returns a supervisor child specification for the HTTP client
  - `request/3` - Makes an HTTP POST request with the given URL, payload, and headers

  ## Headers Format

  Headers should be provided as a list of `{name, value}` tuples, where both
  name and value are strings. This matches `Mint.Types.headers()` format.

  ## Response Format

  Successful responses should return:
  ```elixir
  {:ok, %{status: integer(), headers: list(), body: binary()}}
  ```

  Errors should return:
  ```elixir
  {:error, term()}
  ```
  """

  @type headers() :: [{String.t(), String.t()}]

  @callback child_spec() :: :supervisor.child_spec()
  @callback post(url :: String.t(), payload :: binary(), headers :: headers()) ::
              {:ok, %{status: integer(), headers: headers(), body: binary()}}
              | {:error, term()}
end

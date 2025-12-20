defmodule ExLivekit.Client do
  @moduledoc """
  Client for making requests to the LiveKit API.

  This module provides a high-level interface for interacting with LiveKit services.
  It handles authentication, request formatting, and response parsing.

  ## Configuration

  Create a client with required configuration:

      client = ExLivekit.Client.new(
        host: "https://api.livekit.io",
        api_key: "your_api_key",
        api_secret: "your_api_secret"
      )

  Or configure via application environment:

      config :ex_livekit,
        host: "https://api.livekit.io",
        api_key: "your_api_key",
        api_secret: "your_api_secret"

      client = ExLivekit.Client.new()

  ## Making Requests

  Use `send_request/5` to make API calls:

      auth_headers = ExLivekit.Client.auth_headers(client)
      {:ok, response_body} = ExLivekit.Client.send_request(client, "RoomService", "CreateRoom", payload, auth_headers)
  """

  alias ExLivekit.AccessToken
  alias ExLivekit.Config
  alias ExLivekit.Grants.{SIPGrant, VideoGrant}

  defstruct [:host, :api_key, :api_secret]

  @type t :: %__MODULE__{
          host: String.t(),
          api_key: String.t(),
          api_secret: String.t()
        }

  @base_headers [
    {"User-Agent", "Livekit Elixir SDK"},
    {"Content-Type", "application/protobuf"}
  ]

  @doc """
  Creates a new LiveKit client.

  ## Options

    * `:host` - The LiveKit server host (required)
    * `:api_key` - Your LiveKit API key (required)
    * `:api_secret` - Your LiveKit API secret (required)

  If options are not provided, they will be fetched from the application environment.

  ## Examples

      iex> client = ExLivekit.Client.new(
      ...>   host: "https://api.livekit.io",
      ...>   api_key: "key",
      ...>   api_secret: "secret"
      ...> )
      %ExLivekit.Client{...}
  """
  @spec new(Keyword.t()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      host: Config.fetch_from_opts!(:host, opts),
      api_key: Config.fetch_from_opts!(:api_key, opts),
      api_secret: Config.fetch_from_opts!(:api_secret, opts)
    }
  end

  @doc """
  Sends an HTTP request to the LiveKit API.

  ## Parameters

    * `client` - The `ExLivekit.Client` struct
    * `svc` - The service name (e.g., "RoomService")
    * `method` - The method name (e.g., "CreateRoom")
    * `payload` - The request payload as a binary (protobuf encoded)
    * `auth_headers` - Authorization headers (default: `[]`)

  ## Returns

    * `{:ok, body}` - Success with response body
    * `{:error, %{status: status, body: body}}` - HTTP error response
    * `{:error, term()}` - Request error

  ## Examples

      {:ok, response} = ExLivekit.Client.send_request(
        client,
        "RoomService",
        "CreateRoom",
        protobuf_payload,
        auth_headers
      )
  """
  @spec send_request(t(), String.t(), String.t(), binary(), list()) ::
          {:ok, binary()} | {:error, map() | term()}
  def send_request(%__MODULE__{} = client, svc, method, payload, auth_headers \\ []) do
    url = prepare_url(client.host, svc, method)
    http_client = Config.http_client()
    headers = auth_headers ++ @base_headers

    case http_client.post(url, payload, headers) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Generates authorization headers for API requests.

  ## Parameters

    * `client` - The `ExLivekit.Client` struct
    * `opts` - Options for token generation
      * `:video_grant` - Optional `ExLivekit.Grants.VideoGrant` struct
      * `:sip_grant` - Optional `ExLivekit.Grants.SIPGrant` struct

  ## Returns

    A list of header tuples containing the Authorization header.

  ## Examples

      headers = ExLivekit.Client.auth_headers(client)
      # => [{"Authorization", "Bearer ..."}]

      headers = ExLivekit.Client.auth_headers(client, video_grant: video_grant)
      # => [{"Authorization", "Bearer ..."}]
  """
  @spec auth_headers(t(), Keyword.t()) :: [{String.t(), String.t()}]
  def auth_headers(%__MODULE__{} = client, opts \\ []) do
    token =
      AccessToken.new(api_key: client.api_key, api_secret: client.api_secret)
      |> handle_video_grant(opts[:video_grant])
      |> handle_sip_grant(opts[:sip_grant])

    [
      {"Authorization", "Bearer #{AccessToken.to_jwt(token)}"}
    ]
  end

  defp handle_video_grant(token, %VideoGrant{} = video_grant),
    do: AccessToken.add_grants(token, video_grant)

  defp handle_video_grant(token, nil), do: token

  defp handle_sip_grant(token, %SIPGrant{} = sip_grant),
    do: AccessToken.add_sip_grants(token, sip_grant)

  defp handle_sip_grant(token, nil), do: token

  defp prepare_url(host, svc, method) do
    "#{ExLivekit.Utils.to_http_url(host)}/twirp/livekit.#{svc}/#{method}"
  end
end

defmodule ExLivekit.Client.Finch do
  @moduledoc """
  Finch-based HTTP client implementation for ExLivekit.

  This module implements the `ExLivekit.Client.HTTPClient` behaviour using
  the Finch HTTP client library. It provides connection pooling and
  configurable timeouts.

  ## Configuration

  Configure Finch options via application environment:

      config :ex_livekit,
        http_client: :finch,
        finch_opts: [receive_timeout: 30_000],
        finch_pool_opts: [size: 10]

  See the Finch documentation for available options.
  """

  use ExLivekit.Client.HTTPClient

  @impl ExLivekit.Client.HTTPClient
  def child_spec do
    if Code.ensure_loaded?(:finch) do
      case Application.ensure_all_started(:finch) do
        {:ok, _apps} -> :ok
        {:error, reason} -> raise "failed to start the :finch application: #{inspect(reason)}"
      end

      opts = Keyword.merge(ExLivekit.Config.finch_pool_opts(), name: __MODULE__)

      Finch.child_spec(opts)
    else
      raise """
      cannot start the :ex_livekit application because the HTTP client is set to \
      ExLivekit.Client.Finch, but the Finch library is not loaded. \
      Add :finch to your dependencies to fix this.
      """
    end
  end

  @impl ExLivekit.Client.HTTPClient
  def post(url, payload, headers \\ []) do
    request_opts = ExLivekit.Config.finch_opts()
    request = Finch.build(:post, url, headers, payload)

    case Finch.request(request, __MODULE__, request_opts) do
      {:ok, response} ->
        {:ok, %{status: response.status, headers: response.headers, body: response.body}}

      {:error, %{reason: reason}} when reason in @client_error_reasons ->
        {:error, %{reason: reason}}

      _error ->
        {:error, %{reason: :unknown}}
    end
  end
end

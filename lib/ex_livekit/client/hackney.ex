defmodule ExLivekit.Client.Hackney do
  @moduledoc """
  Hackney-based HTTP client implementation for ExLivekit.

  This module implements the `ExLivekit.Client.HTTPClient` behaviour using
  the Hackney HTTP client library. It provides connection pooling and
  configurable timeouts.

  ## Configuration

  Configure Hackney options via application environment:

      config :ex_livekit,
        hackney_opts: [timeout: 30_000, connect_timeout: 10_000],
        hackney_pool_opts: [timeout: 30_000, max_connections: 50]

  See the Hackney documentation for available options.
  """

  use ExLivekit.Client.HTTPClient
  alias ExLivekit.Config

  @impl ExLivekit.Client.HTTPClient
  def child_spec do
    if Code.ensure_loaded?(:hackney) and Code.ensure_loaded?(:hackney_pool) do
      case Application.ensure_all_started(:hackney) do
        {:ok, _apps} -> :ok
        {:error, reason} -> raise "failed to start the :hackney application: #{inspect(reason)}"
      end

      :hackney_pool.child_spec(
        __MODULE__,
        Config.hackney_pool_opts()
      )
    else
      raise """
      cannot start the :ex_livekit application because the HTTP client is set to \
      ExLivekit.Client.Hackney (which is the default), but the Hackney library is not loaded. \
      Add :hackney to your dependencies to fix this.
      """
    end
  end

  @impl ExLivekit.Client.HTTPClient
  def post(url, payload, headers \\ []) do
    opts = [:with_body | Config.hackney_opts()]

    case :hackney.request(:post, url, headers, payload, opts) do
      # With :with_body, Hackney should always return a body, but handle edge case
      {:ok, status, headers} ->
        {:ok, %{status: status, headers: headers, body: ""}}

      {:ok, status, headers, body} ->
        {:ok, %{status: status, headers: headers, body: body}}

      {:error, reason} when reason in @client_error_reasons ->
        {:error, %{reason: reason}}

      _error ->
        {:error, %{reason: :unknown}}
    end
  end
end

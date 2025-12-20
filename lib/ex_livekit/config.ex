defmodule ExLivekit.Config do
  @moduledoc false

  @default_config [
    http_client: :hackney,
    hackney_opts: [timeout: 30_000],
    finch_opts: [receive_timeout: 30_000],
    hackney_pool_opts: [timeout: 30_000, max_connections: 50],
    finch_pool_opts: []
  ]

  @http_clients [
    hackney: ExLivekit.Client.Hackney,
    finch: ExLivekit.Client.Finch
  ]

  @spec http_client() :: module :: atom()
  def http_client, do: Keyword.fetch!(@http_clients, fetch!(:http_client))

  @spec hackney_opts() :: Keyword.t()
  def hackney_opts, do: get_and_merge_with_default(:hackney_opts)

  @spec hackney_pool_opts() :: Keyword.t()
  def hackney_pool_opts, do: get_and_merge_with_default(:hackney_pool_opts)

  @spec finch_opts() :: Keyword.t()
  def finch_opts, do: get_and_merge_with_default(:finch_opts)

  @spec finch_pool_opts() :: Keyword.t()
  def finch_pool_opts, do: get_and_merge_with_default(:finch_pool_opts)

  @spec fetch_from_opts!(key :: atom(), opts :: Keyword.t()) :: any()
  def fetch_from_opts!(key, opts) do
    result = opts[key] || Application.get_env(:ex_livekit, key)

    if is_nil(result) or result == "" do
      raise "config option #{key} is not set in the opts or the environment"
    end

    result
  end

  @doc false
  def default_config, do: @default_config

  defp fetch!(key), do: Application.get_env(:ex_livekit, key, @default_config[key])

  defp get_and_merge_with_default(key) do
    env_opts = Application.get_env(:ex_livekit, key, [])
    Keyword.merge(@default_config[key], env_opts)
  end
end

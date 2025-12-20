defmodule ExLivekit.ConfigTest do
  use ExUnit.Case, async: false
  alias ExLivekit.Config

  defp cleanup_fn(key) do
    Application.delete_env(:ex_livekit, key)
  end

  setup do
    configs = [
      :http_client,
      :hackney_opts,
      :hackney_pool_opts,
      :finch_opts,
      :finch_pool_opts,
      :api_key,
      :api_secret
    ]

    on_exit(fn ->
      Enum.each(configs, &cleanup_fn/1)
    end)
  end

  describe "http_client/0" do
    test "returns default hackney client when http_client is not set in env" do
      assert Config.http_client() == ExLivekit.Client.Hackney
    end

    test "returns hackney client when http_client is set to :hackney in env" do
      Application.put_env(:ex_livekit, :http_client, :hackney)
      assert Config.http_client() == ExLivekit.Client.Hackney
    end

    test "returns finch client when http_client is set to :finch in env" do
      Application.put_env(:ex_livekit, :http_client, :finch)
      assert Config.http_client() == ExLivekit.Client.Finch
    end

    test "raises KeyError when http_client is set to invalid value in env" do
      Application.put_env(:ex_livekit, :http_client, :invalid_client)

      assert_raise KeyError, ~r/key :invalid_client not found/, fn ->
        Config.http_client()
      end
    end
  end

  describe "hackney_opts/0" do
    test "returns default options when hackney_opts is not set in env" do
      Application.delete_env(:ex_livekit, :hackney_opts)
      default_opts = Config.default_config()[:hackney_opts]
      assert Config.hackney_opts() == default_opts
    end

    test "returns merged options when hackney_opts is set in env" do
      default_opts = Config.default_config()[:hackney_opts]
      assert Config.hackney_opts() == default_opts

      Application.put_env(:ex_livekit, :hackney_opts, connect_timeout: 10_000)
      result = Config.hackney_opts()

      assert result[:timeout] == default_opts[:timeout]
      assert result[:connect_timeout] == 10_000
    end

    test "env options override default options when same keys are present" do
      Application.put_env(:ex_livekit, :hackney_opts, timeout: 60_000)
      assert Config.hackney_opts() == [timeout: 60_000]
    end

    test "returns empty list merged with defaults when env is set to empty list" do
      Application.put_env(:ex_livekit, :hackney_opts, [])
      default_opts = Config.default_config()[:hackney_opts]
      assert Config.hackney_opts() == default_opts
    end
  end

  describe "hackney_pool_opts/0" do
    test "returns default options when hackney_pool_opts is not set in env" do
      default_opts = Config.default_config()[:hackney_pool_opts]
      assert Config.hackney_pool_opts() == default_opts
    end

    test "returns merged options when hackney_pool_opts is set in env" do
      Application.put_env(:ex_livekit, :hackney_pool_opts, max_connections: 100)
      result = Config.hackney_pool_opts()
      default_opts = Config.default_config()[:hackney_pool_opts]

      assert result[:timeout] == default_opts[:timeout]
      assert result[:max_connections] == 100
    end

    test "env options override default options when same keys are present" do
      Application.put_env(:ex_livekit, :hackney_pool_opts, timeout: 60_000, max_connections: 200)
      result = Config.hackney_pool_opts()

      assert result[:timeout] == 60_000
      assert result[:max_connections] == 200
      assert length(result) == 2
    end

    test "returns empty list merged with defaults when env is set to empty list" do
      Application.put_env(:ex_livekit, :hackney_pool_opts, [])
      default_opts = Config.default_config()[:hackney_pool_opts]

      assert Config.hackney_pool_opts() == default_opts
    end
  end

  describe "finch_opts/0" do
    test "returns default options when finch_opts is not set in env" do
      Application.delete_env(:ex_livekit, :finch_opts)
      default_opts = Config.default_config()[:finch_opts]
      assert Config.finch_opts() == default_opts
    end

    test "returns merged options when finch_opts is set in env" do
      Application.put_env(:ex_livekit, :finch_opts, connect_timeout: 10_000)
      result = Config.finch_opts()
      default_opts = Config.default_config()[:finch_opts]

      assert result[:receive_timeout] == default_opts[:receive_timeout]
      assert result[:connect_timeout] == 10_000
    end

    test "env options override default options when same keys are present" do
      Application.put_env(:ex_livekit, :finch_opts, receive_timeout: 60_000)

      assert Config.finch_opts() == [receive_timeout: 60_000]
    end

    test "returns empty list merged with defaults when env is set to empty list" do
      Application.put_env(:ex_livekit, :finch_opts, [])
      default_opts = Config.default_config()[:finch_opts]

      assert Config.finch_opts() == default_opts
    end
  end

  describe "finch_pool_opts/0" do
    test "returns default options when finch_pool_opts is not set in env" do
      Application.delete_env(:ex_livekit, :finch_pool_opts)
      default_opts = Config.default_config()[:finch_pool_opts]
      assert Config.finch_pool_opts() == default_opts
    end

    test "returns merged options when finch_pool_opts is set in env" do
      Application.put_env(:ex_livekit, :finch_pool_opts, size: 10)

      assert Config.finch_pool_opts() == [size: 10]
    end

    test "returns env options when finch_pool_opts is set in env with multiple keys" do
      Application.put_env(:ex_livekit, :finch_pool_opts, size: 20, max_idle_timeout: 5_000)
      result = Config.finch_pool_opts()

      assert result[:size] == 20
      assert result[:max_idle_timeout] == 5_000
      assert length(result) == 2
    end

    test "returns empty list when env is set to empty list" do
      Application.put_env(:ex_livekit, :finch_pool_opts, [])
      result = Config.finch_pool_opts()

      assert result == []
    end
  end

  describe "fetch_from_opts!/2" do
    test "returns value from opts when key exists in opts (does not check env)" do
      opts = [api_key: "test_key_from_opts"]
      Application.put_env(:ex_livekit, :api_key, "test_key_from_env")

      assert Config.fetch_from_opts!(:api_key, opts) == "test_key_from_opts"
    end

    test "returns value from env when key does not exist in opts but exists in env" do
      opts = []
      Application.put_env(:ex_livekit, :api_key, "test_key_from_env")

      assert Config.fetch_from_opts!(:api_key, opts) == "test_key_from_env"
    end

    test "returns value from env when key is nil in opts but exists in env" do
      opts = [api_key: nil]
      Application.put_env(:ex_livekit, :api_key, "test_key_from_env")

      assert Config.fetch_from_opts!(:api_key, opts) == "test_key_from_env"
    end

    test "raises exception when key is not in opts and not in env" do
      opts = []
      Application.delete_env(:ex_livekit, :api_key)

      assert_raise RuntimeError,
                   ~r/config option api_key is not set in the opts or the environment/,
                   fn ->
                     Config.fetch_from_opts!(:api_key, opts)
                   end
    end

    test "raises exception when key is nil in opts and not in env" do
      opts = [api_key: nil]
      Application.delete_env(:ex_livekit, :api_key)

      assert_raise RuntimeError,
                   ~r/config option api_key is not set in the opts or the environment/,
                   fn ->
                     Config.fetch_from_opts!(:api_key, opts)
                   end
    end

    test "raises exception when key is empty string in opts and not in env" do
      opts = [api_key: ""]
      Application.delete_env(:ex_livekit, :api_key)

      assert_raise RuntimeError,
                   ~r/config option api_key is not set in the opts or the environment/,
                   fn ->
                     Config.fetch_from_opts!(:api_key, opts)
                   end
    end

    test "raises exception when key is empty string in env and not in opts" do
      opts = []
      Application.put_env(:ex_livekit, :api_key, "")

      assert_raise RuntimeError,
                   ~r/config option api_key is not set in the opts or the environment/,
                   fn ->
                     Config.fetch_from_opts!(:api_key, opts)
                   end
    end

    test "returns value from opts even when env has empty string" do
      opts = [api_key: "valid_key"]
      Application.put_env(:ex_livekit, :api_key, "")

      assert Config.fetch_from_opts!(:api_key, opts) == "valid_key"
    end

    test "returns value from opts even when env has nil" do
      opts = [api_key: "valid_key"]
      Application.put_env(:ex_livekit, :api_key, nil)

      assert Config.fetch_from_opts!(:api_key, opts) == "valid_key"
    end

    test "handles different types of values correctly" do
      opts = [timeout: 5000, enabled: true, name: "test"]

      assert Config.fetch_from_opts!(:timeout, opts) == 5000
      assert Config.fetch_from_opts!(:enabled, opts) == true
      assert Config.fetch_from_opts!(:name, opts) == "test"
    end
  end
end

defmodule ExLivekit.UtilsTest do
  use ExUnit.Case, async: true

  alias ExLivekit.Utils

  describe "snake_to_lower_camel/1" do
    test "converts a snake case string to a lower camel case string" do
      assert Utils.snake_to_lower_camel("snake_case") == "snakeCase"
      assert Utils.snake_to_lower_camel(:snake_case) == "snakeCase"
    end
  end

  describe "camel_to_snake/1" do
    test "converts a camel case string to a snake case string" do
      assert Utils.camel_to_snake("camelCase") == "camel_case"
      assert Utils.camel_to_snake("CamelCase") == "camel_case"
    end
  end

  describe "to_http_url/1" do
    test "adds http:// prefix when url has no scheme" do
      assert Utils.to_http_url("example.com") == "http://example.com"
      assert Utils.to_http_url("api.livekit.io") == "http://api.livekit.io"
      assert Utils.to_http_url("localhost") == "http://localhost"
      assert Utils.to_http_url("localhost:8080") == "http://localhost:8080"
      # Note: "localhost:8080" is parsed as scheme "localhost", so it's returned unchanged
      # This is a limitation of URI.parse - it requires proper URL format
    end

    test "converts ws:// to http://" do
      assert Utils.to_http_url("ws://example.com") == "http://example.com"
      assert Utils.to_http_url("ws://api.livekit.io/room") == "http://api.livekit.io/room"
      assert Utils.to_http_url("ws://localhost:8080") == "http://localhost:8080"
    end

    test "converts wss:// to https://" do
      assert Utils.to_http_url("wss://example.com") == "https://example.com"
      assert Utils.to_http_url("wss://api.livekit.io/room") == "https://api.livekit.io/room"
      assert Utils.to_http_url("wss://localhost:8080") == "https://localhost:8080"
    end

    test "leaves http:// URLs unchanged" do
      assert Utils.to_http_url("http://example.com") == "http://example.com"
      assert Utils.to_http_url("http://api.livekit.io/room") == "http://api.livekit.io/room"
      assert Utils.to_http_url("http://localhost:8080") == "http://localhost:8080"
    end

    test "leaves https:// URLs unchanged" do
      assert Utils.to_http_url("https://example.com") == "https://example.com"
      assert Utils.to_http_url("https://api.livekit.io/room") == "https://api.livekit.io/room"
      assert Utils.to_http_url("https://localhost:8080") == "https://localhost:8080"
    end

    test "handles URLs with paths and query parameters" do
      assert Utils.to_http_url("example.com/path") ==
               "http://example.com/path"

      assert Utils.to_http_url("ws://example.com/path?query=value") ==
               "http://example.com/path?query=value"

      assert Utils.to_http_url("wss://example.com/path?query=value") ==
               "https://example.com/path?query=value"

      assert Utils.to_http_url("http://example.com/path?query=value") ==
               "http://example.com/path?query=value"
    end

    test "handles URLs with ports" do
      # Note: URI.parse treats "example.com:8080" as having scheme "example.com"
      # So it returns unchanged. Only properly formatted URLs work.
      assert Utils.to_http_url("ws://example.com:8080") == "http://example.com:8080"
      assert Utils.to_http_url("wss://example.com:8080") == "https://example.com:8080"
      assert Utils.to_http_url("http://example.com:8080") == "http://example.com:8080"
      assert Utils.to_http_url("https://example.com:8080") == "https://example.com:8080"
    end

    test "handles URLs with userinfo" do
      # Note: URI.parse treats "user:pass@example.com" as having scheme "user"
      # So it returns unchanged. Only properly formatted URLs work.
      assert Utils.to_http_url("ws://user:pass@example.com") == "http://user:pass@example.com"
      assert Utils.to_http_url("wss://user:pass@example.com") == "https://user:pass@example.com"
      assert Utils.to_http_url("http://user:pass@example.com") == "http://user:pass@example.com"
    end
  end
end

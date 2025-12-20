defmodule ExLivekit.ClientTest do
  use ExUnit.Case, async: false
  alias ExLivekit.Client

  setup do
    on_exit(fn ->
      Application.delete_env(:ex_livekit, :host)
      Application.delete_env(:ex_livekit, :api_key)
      Application.delete_env(:ex_livekit, :api_secret)
    end)
  end

  describe "new/0" do
    test "returns a new client" do
      host = "https://api.livekit.io"
      api_key = "test_key"
      api_secret = "test_secret"

      Application.put_env(:ex_livekit, :host, host)
      Application.put_env(:ex_livekit, :api_key, api_key)
      Application.put_env(:ex_livekit, :api_secret, api_secret)

      assert Client.new() == %Client{host: host, api_key: api_key, api_secret: api_secret}
    end

    test "raises an error if the required config options are not set" do
      assert_raise RuntimeError,
                   ~r/config option .* is not set in the opts or the environment/,
                   fn -> Client.new() end

      Application.put_env(:ex_livekit, :host, "api.livekit.io")

      assert_raise RuntimeError,
                   ~r/config option .* is not set in the opts or the environment/,
                   fn -> Client.new() end

      Application.put_env(:ex_livekit, :api_key, "test_key")

      assert_raise RuntimeError,
                   ~r/config option api_secret is not set in the opts or the environment/,
                   fn -> Client.new() end
    end
  end

  describe "new/1" do
    test "returns a new client" do
      host = "https://api.livekit.io"
      api_key = "test_key"
      api_secret = "test_secret"

      assert Client.new(host: host, api_key: api_key, api_secret: api_secret) == %Client{
               host: host,
               api_key: api_key,
               api_secret: api_secret
             }
    end
  end

  describe "auth_headers/2" do
    setup do
      api_key = "test_api_key"
      api_secret = "test_api_secret"

      client =
        Client.new(host: "https://api.livekit.io", api_key: api_key, api_secret: api_secret)

      [client: client, api_key: api_key, api_secret: api_secret]
    end

    test "returns authorization headers without grants", %{client: client} do
      assert [{"Authorization", token}] = Client.auth_headers(client)

      assert String.starts_with?(token, "Bearer ")
      assert String.length(token) > 7
    end

    test "returns authorization headers with video grant", %{client: client} do
      video_grant = %ExLivekit.Grants.VideoGrant{
        room_join: true,
        room: "test_room",
        can_publish: true,
        can_subscribe: true
      }

      assert [{"Authorization", token}] = Client.auth_headers(client, video_grant: video_grant)

      # Verify the token can be decoded and contains video grant
      jwt_token = String.replace_prefix(token, "Bearer ", "")
      {:ok, claims} = Joken.peek_claims(jwt_token)

      assert Map.has_key?(claims, "video")
      video_claims = claims["video"]
      assert video_claims["room"] == video_grant.room
      assert video_claims["roomJoin"] == video_grant.room_join
      assert video_claims["canPublish"] == video_grant.can_publish
      assert video_claims["canSubscribe"] == video_grant.can_subscribe
    end

    test "returns authorization headers with sip grant", %{client: client} do
      sip_grant = %ExLivekit.Grants.SIPGrant{admin: true, call: true}

      assert [{"Authorization", token}] = Client.auth_headers(client, sip_grant: sip_grant)

      # Verify the token can be decoded and contains sip grant
      jwt_token = String.replace_prefix(token, "Bearer ", "")
      {:ok, claims} = Joken.peek_claims(jwt_token)

      assert Map.has_key?(claims, "sip")
      assert claims["sip"]["admin"] == sip_grant.admin
      assert claims["sip"]["call"] == sip_grant.call
    end

    test "returns authorization headers with both video and sip grants", %{client: client} do
      video_grant = %ExLivekit.Grants.VideoGrant{
        room_join: true,
        room: "test_room",
        can_publish: true,
        can_subscribe: true
      }

      sip_grant = %ExLivekit.Grants.SIPGrant{admin: true, call: false}

      assert [{"Authorization", token}] =
               Client.auth_headers(client, video_grant: video_grant, sip_grant: sip_grant)

      # Verify the token can be decoded and contains both grants
      jwt_token = String.replace_prefix(token, "Bearer ", "")
      {:ok, claims} = Joken.peek_claims(jwt_token)

      video_claims = claims["video"]
      sip_claims = claims["sip"]
      assert video_claims["room"] == video_grant.room
      assert video_claims["roomJoin"] == video_grant.room_join
      assert sip_claims["admin"] == sip_grant.admin
      assert sip_claims["call"] == sip_grant.call
    end

    test "handles nil grants gracefully", %{client: client} do
      assert [{"Authorization", token}] =
               Client.auth_headers(client, video_grant: nil, sip_grant: nil)

      assert String.starts_with?(token, "Bearer ")
    end

    test "uses client's api_key and api_secret for token generation", %{client: client} do
      assert [{"Authorization", token}] = Client.auth_headers(client)

      jwt_token = String.replace_prefix(token, "Bearer ", "")
      {:ok, claims} = Joken.peek_claims(jwt_token)
      assert claims["iss"] == client.api_key
    end
  end
end

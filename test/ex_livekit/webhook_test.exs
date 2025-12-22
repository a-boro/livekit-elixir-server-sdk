defmodule ExLivekit.WebhookTest do
  use ExUnit.Case

  alias ExLivekit.Webhook

  defp base_json_event do
    %Livekit.WebhookEvent{event: "track_published"}
    |> Protobuf.JSON.encode!()
  end

  describe "receive_event/2" do
    setup do
      on_exit(fn ->
        Application.delete_env(:ex_livekit, :webhook)
        Application.delete_env(:ex_livekit, :api_key)
        Application.delete_env(:ex_livekit, :api_secret)
      end)
    end

    test "returns {:ok, event} when event is valid" do
      event =
        %Livekit.WebhookEvent{
          event: "track_published",
          id: "EV_abcde",
          created_at: 1_719_000_000,
          room: %Livekit.Room{
            sid: "RM_abcde",
            name: "test_room",
            creation_time: 1_719_000_000,
            creation_time_ms: 1_719_000_000,
            turn_password: "test_turn_password",
            metadata: "test_metadata",
            num_participants: 1,
            num_publishers: 1,
            active_recording: true
          },
          participant: %Livekit.ParticipantInfo{
            identity: "test_identity",
            sid: "PA_abcde",
            joined_at: 1_719_000_000,
            joined_at_ms: 1_719_000_000,
            name: "test_name",
            version: 1,
            permission: %Livekit.ParticipantPermission{can_publish: true, can_subscribe: true},
            region: "us-east-1"
          },
          track: %Livekit.TrackInfo{
            sid: "TR_abcde",
            name: "test_track",
            type: :VIDEO,
            source: :CAMERA,
            mime_type: "video/webm"
          }
        }

      json_event = Protobuf.JSON.encode!(event)

      api_key = "test_api_key"
      api_secret = "test_api_secret"
      Application.put_env(:ex_livekit, :api_key, api_key)
      Application.put_env(:ex_livekit, :api_secret, api_secret)

      sha256 = :crypto.hash(:sha256, json_event) |> Base.encode64()

      auth_token =
        ExLivekit.AccessToken.new(api_key: api_key, api_secret: api_secret)
        |> ExLivekit.AccessToken.add_sha256(sha256)
        |> ExLivekit.AccessToken.to_jwt()

      auth_token_with_bearer = "Bearer " <> auth_token

      assert Webhook.receive_event(json_event, auth_token) == {:ok, event}
      assert Webhook.receive_event(json_event, auth_token_with_bearer) == {:ok, event}
    end
  end

  describe "validate_sha256/2" do
    test "returns :ok when sha256 is valid" do
      event = base_json_event()
      sha256 = :crypto.hash(:sha256, event) |> Base.encode64()

      assert Webhook.validate_sha256(event, sha256) == :ok
    end

    test "returns {:error, :invalid_sha256} when sha256 is nil" do
      event = base_json_event()
      assert Webhook.validate_sha256(event, nil) == {:error, :invalid_sha256}
    end

    test "returns {:error, :invalid_sha256} when sha256 is empty" do
      event = base_json_event()
      assert Webhook.validate_sha256(event, "") == {:error, :invalid_sha256}
    end
  end

  describe "get_webhook_config" do
    setup do
      on_exit(fn ->
        Application.delete_env(:ex_livekit, :webhook)
        Application.delete_env(:ex_livekit, :api_key)
        Application.delete_env(:ex_livekit, :api_secret)
      end)
    end

    test "returns {:ok, config} when webhook config is set in env" do
      api_key = "test_api_key"
      api_secret = "test_api_secret"
      Application.put_env(:ex_livekit, :webhook, api_key: api_key, api_secret: api_secret)

      assert {:ok, config} = Webhook.get_webhook_config()
      assert config.api_key == api_key
      assert config.api_secret == api_secret
    end

    test "returns {:ok, config} when webhook config is not set but api_key and api_secret are set in env" do
      api_key = "test_api_key"
      api_secret = "test_api_secret"
      Application.put_env(:ex_livekit, :api_key, api_key)
      Application.put_env(:ex_livekit, :api_secret, api_secret)

      assert {:ok, config} = Webhook.get_webhook_config()
      assert config.api_key == api_key
      assert config.api_secret == api_secret
    end

    test "returns {:error, :webhook_not_configured} when webhook config is not set in env" do
      assert Webhook.get_webhook_config() == {:error, :webhook_not_configured}
    end
  end
end

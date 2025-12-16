defmodule ExLivekit.AccessTokenTest do
  use ExUnit.Case, async: false

  alias ExLivekit.AccessToken

  @api_key "api_key"
  @api_secret "api_secret"
  @default_ttl 3600

  describe "new/0" do
    test "returns a new access token" do
      config_api_key = "test_api_key"
      config_api_secret = "test_api_secret"

      Application.put_env(:ex_livekit, :livekit_api_key, config_api_key)
      Application.put_env(:ex_livekit, :livekit_api_secret, config_api_secret)

      access_token = AccessToken.new()

      assert %AccessToken{
               api_key: config_api_key,
               api_secret: config_api_secret,
               grants: %ExLivekit.Grants.ClaimGrant{},
               ttl: @default_ttl
             } == access_token

      Application.delete_env(:ex_livekit, :livekit_api_key)
      Application.delete_env(:ex_livekit, :livekit_api_secret)
    end
  end

  describe "new/2" do
    test "returns a new access token" do
      access_token = AccessToken.new(@api_key, @api_secret)

      assert %AccessToken{
               api_key: @api_key,
               api_secret: @api_secret,
               grants: %ExLivekit.Grants.ClaimGrant{},
               ttl: @default_ttl
             } == access_token
    end
  end

  describe "add_identity/2" do
    test "adds identity to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      identity = "test_identity"

      access_token = AccessToken.add_identity(access_token, identity)
      assert access_token.grants.identity == identity
    end
  end

  describe "add_ttl/2" do
    test "adds ttl to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      ttl = @default_ttl + 1

      access_token = AccessToken.add_ttl(access_token, ttl)

      assert access_token.ttl == ttl
    end
  end

  describe "add_metadata/2" do
    test "adds metadata to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      metadata = "test_metadata"

      access_token = AccessToken.add_metadata(access_token, metadata)

      assert access_token.grants.metadata == metadata
    end
  end

  describe "add_name/2" do
    test "adds name to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      name = "test_name"

      access_token = AccessToken.add_name(access_token, name)

      assert access_token.grants.name == name
    end
  end

  describe "add_kind/2" do
    test "adds kind to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      kind = :standard

      access_token = AccessToken.add_kind(access_token, kind)

      assert access_token.grants.kind == kind
    end
  end

  describe "add_sip_grants/2" do
    test "adds sip grants to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      sip_grants = %ExLivekit.Grants.SIPGrant{admin: true, call: true}

      access_token = AccessToken.add_sip_grants(access_token, sip_grants)

      assert access_token.grants.sip == sip_grants
    end
  end

  describe "add_inference_grants/2" do
    test "adds inference grants to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      inference_grants = %ExLivekit.Grants.InferenceGrant{perform: true}

      access_token = AccessToken.add_inference_grants(access_token, inference_grants)

      assert access_token.grants.inference == inference_grants
    end
  end

  describe "add_attributes/2" do
    test "adds attributes to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      attributes = %{"test_attribute" => "test_value"}

      access_token = AccessToken.add_attributes(access_token, attributes)

      assert access_token.grants.attributes == attributes
    end
  end

  describe "add_room_preset/2" do
    test "adds room preset to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      room_preset = "test_room_preset"

      access_token = AccessToken.add_room_preset(access_token, room_preset)

      assert access_token.grants.room_preset == room_preset
    end
  end

  describe "add_sha256/2" do
    test "adds sha256 to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      sha256 = "test_sha256"

      access_token = AccessToken.add_sha256(access_token, sha256)

      assert access_token.grants.sha256 == sha256
    end
  end

  describe "add_observability_grants/2" do
    test "adds observability grants to the access token" do
      access_token = AccessToken.new(@api_key, @api_secret)
      observability_grants = %ExLivekit.Grants.ObservabilityGrant{write: true}

      access_token = AccessToken.add_observability_grants(access_token, observability_grants)

      assert access_token.grants.observability == observability_grants
    end
  end

  describe "add_grants/2" do
    test "adds first grants to the access token when grants are struct" do
      access_token = AccessToken.new(@api_key, @api_secret)
      grants = %ExLivekit.Grants.VideoGrant{room_create: true}

      access_token = AccessToken.add_grants(access_token, grants)

      assert access_token.grants.video == grants
    end

    test "adds first grants to the access token when grants are map" do
      access_token = AccessToken.new(@api_key, @api_secret)
      grants = %{room_create: true}

      access_token = AccessToken.add_grants(access_token, grants)

      assert access_token.grants.video == %ExLivekit.Grants.VideoGrant{room_create: true}
    end

    test "merges grants when grants are map" do
      access_token = AccessToken.new(@api_key, @api_secret)

      access_token =
        AccessToken.add_grants(access_token, %ExLivekit.Grants.VideoGrant{room_list: true})

      grants = %{room_create: true}

      access_token = AccessToken.add_grants(access_token, grants)

      assert access_token.grants.video == %ExLivekit.Grants.VideoGrant{
               room_create: true,
               room_list: true
             }
    end
  end

  describe "to_jwt/1" do
    test "converts the access token to a JWT" do
      access_token = AccessToken.new(@api_key, @api_secret)
      jwt = AccessToken.to_jwt(access_token)

      assert is_binary(jwt)

      signer = Joken.Signer.create("HS256", @api_secret)

      {:ok, claims} = Joken.verify(jwt, signer)

      assert claims["iss"] == @api_key
      assert claims["sub"] == ""
      assert claims["nbf"] < claims["exp"]
    end
  end
end

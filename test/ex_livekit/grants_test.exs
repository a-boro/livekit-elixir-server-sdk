defmodule ExLivekit.GrantsTest do
  use ExUnit.Case, async: true

  describe "ClaimGrant.to_jwt_payload/1" do
    test "converts a grant to a JWT payload and removes the identity key and none values" do
      identity = "test_identity"
      attributes = %{"test_attribute" => "test_value"}
      video = %ExLivekit.Grants.VideoGrant{room_create: true}
      name = "test_name"

      grant = %ExLivekit.Grants.ClaimGrant{
        identity: identity,
        attributes: attributes,
        video: video,
        name: name
      }

      jwt_payload = ExLivekit.Grants.ClaimGrant.to_jwt_payload(grant)

      assert jwt_payload["attributes"] == attributes
      assert jwt_payload["name"] == name
      assert jwt_payload["video"] == %{"roomCreate" => true}
      refute jwt_payload["identity"]
    end
  end
end

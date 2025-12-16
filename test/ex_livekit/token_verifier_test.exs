defmodule ExLivekit.TokenVerifierTest do
  use ExUnit.Case, async: true

  alias ExLivekit.TokenVerifier
  alias ExLivekit.AccessToken
  alias ExLivekit.Grants.VideoGrant
  alias ExLivekit.Grants.ObservabilityGrant
  alias ExLivekit.Grants.SIPGrant
  alias ExLivekit.Grants.InferenceGrant

  @api_key "api_key"
  @api_secret "api_secret"

  describe "verify/1" do
    test "verifies a token" do
      token =
        AccessToken.new(@api_key, @api_secret)
        |> AccessToken.add_identity("test_identity")
        |> AccessToken.add_ttl(3600)
        |> AccessToken.add_metadata("test_metadata")
        |> AccessToken.add_name("test_name")
        |> AccessToken.add_grants(%VideoGrant{room_create: true})
        |> AccessToken.add_observability_grants(%ObservabilityGrant{write: true})
        |> AccessToken.add_kind(:standard)
        |> AccessToken.add_sip_grants(%SIPGrant{admin: true, call: true})
        |> AccessToken.add_inference_grants(%InferenceGrant{perform: true})
        |> AccessToken.add_attributes(%{"test_attribute" => "test_value"})
        |> AccessToken.add_room_preset("test_room_preset")
        |> AccessToken.add_sha256("test_sha256")
        |> AccessToken.to_jwt()

      assert {:ok, jwt_claims, claims_grant} = TokenVerifier.verify(token, @api_secret)

      assert jwt_claims["sub"] == "test_identity"
      assert jwt_claims["iss"] == @api_key
      assert jwt_claims["nbf"] < jwt_claims["exp"]
      assert claims_grant.identity == "test_identity"
      assert claims_grant.metadata == "test_metadata"
      assert claims_grant.name == "test_name"
      assert claims_grant.video == %VideoGrant{room_create: true}
      assert claims_grant.observability == %ObservabilityGrant{write: true}
      assert claims_grant.kind == "standard"
      assert claims_grant.sip == %SIPGrant{admin: true, call: true}
      assert claims_grant.inference == %InferenceGrant{perform: true}
      assert claims_grant.attributes == %{"test_attribute" => "test_value"}
      assert claims_grant.room_preset == "test_room_preset"
      assert claims_grant.sha256 == "test_sha256"
    end
  end
end

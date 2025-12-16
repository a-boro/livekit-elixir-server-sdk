defmodule ExLivekit.TokenVerifier do
  alias ExLivekit.Grants.{ClaimGrant, VideoGrant, SIPGrant, InferenceGrant, ObservabilityGrant}

  def verify(token) do
    verify(token, Application.fetch_env!(:ex_livekit, :livekit_api_secret))
  end

  def verify(token, api_secret) when is_binary(api_secret) do
    signer = Joken.Signer.create("HS256", api_secret)

    case Joken.verify(token, signer) do
      {:ok, claims} ->
        jwt_claims = jwt_claims_to_snake_map(claims)

        {:ok, jwt_claims, claims_to_struct(jwt_claims)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp jwt_claims_to_snake_map(claims) do
    Map.new(claims, fn {k, v} ->
      if is_map(v) do
        {ExLivekit.Utils.camel_to_snake(k), jwt_claims_to_snake_map(v)}
      else
        {ExLivekit.Utils.camel_to_snake(k), v}
      end
    end)
  end

  @doc false
  def claims_to_struct(claims) do
    prepare_grant = fn claims, grant_key, module ->
      if grant = Map.get(claims, grant_key) do
        string_map_to_struct(grant, module)
      else
        nil
      end
    end

    %ClaimGrant{
      attributes: Map.get(claims, "attributes", %{}),
      identity: Map.get(claims, "sub", ""),
      inference: prepare_grant.(claims, "inference", InferenceGrant),
      kind: Map.get(claims, "kind", ""),
      metadata: Map.get(claims, "metadata", ""),
      name: Map.get(claims, "name", ""),
      observability: prepare_grant.(claims, "observability", ObservabilityGrant),
      room_preset: Map.get(claims, "room_preset", ""),
      sha256: Map.get(claims, "sha256", ""),
      sip: prepare_grant.(claims, "sip", SIPGrant),
      video: prepare_grant.(claims, "video", VideoGrant)
    }
  end

  @doc false
  def string_map_to_struct(string_map, struct_module) when is_map(string_map) do
    struct_map =
      struct_module
      |> Map.from_struct()
      |> Map.new(fn {k, _v} -> {to_string(k), k} end)

    struct(
      struct_module,
      string_map
      |> Stream.map(fn {k, v} -> {struct_map[k], v} end)
      |> Stream.reject(fn {k, _v} -> k in [nil, ""] end)
      |> Map.new()
    )
  end
end

defmodule ExLivekit.TokenVerifier do
  @moduledoc """
  Module for verifying LiveKit access tokens.

  This module provides functionality to verify LiveKit access tokens.
  It handles token verification, signature verification, and claim grant conversion.
  """

  alias ExLivekit.Config
  alias ExLivekit.Grants.{ClaimGrant, InferenceGrant, ObservabilityGrant, SIPGrant, VideoGrant}

  @type verify_opts :: [
          verify_signature: boolean(),
          api_key: binary(),
          api_secret: binary()
        ]

  @doc """
  Verifies a LiveKit access token.

  ## Examples

  ```elixir
  {:ok, jwt_claims, claims_grant} = ExLivekit.TokenVerifier.verify(token)
  ```

  options:
  - verify_signature: true to verify the signature of the token. Default is false.
  - api_key: the API key to use for verification. If not provided, it will use the api_key from the config.
  - api_secret: the API secret to use for verification. If not provided, it will use the api_secret from the config.

  ```elixir
  {:ok, jwt_claims, claims_grant} = ExLivekit.TokenVerifier.verify(token, verify_signature: true, api_key: "api_key", api_secret: "api_secret")
  {:ok, jwt_claims, claims_grant} = ExLivekit.TokenVerifier.verify(token, verify_signature: true, api_key: "api_key")
  {:ok, jwt_claims, claims_grant} = ExLivekit.TokenVerifier.verify(token, verify_signature: true, api_secret: "api_secret")
  ```
  """
  @spec verify(jwt_token :: binary(), verify_opts()) ::
          {:ok, jwt_claims :: map(), claims_grant :: ClaimGrant.t()}
          | {:error, :invalid_token}
          | {:error, :invalid_issuer}
  def verify(token, opts \\ []) do
    api_secret = Config.fetch_from_opts!(:api_secret, opts)
    signer = Joken.Signer.create("HS256", api_secret)

    case Joken.verify(token, signer) do
      {:ok, claims} ->
        jwt_claims = jwt_claims_to_snake_map(claims)
        result = {:ok, jwt_claims, claims_to_struct(jwt_claims)}
        verify_signature = opts[:verify_signature] || false

        if verify_signature do
          verify_signature(result, opts)
        else
          result
        end

      {:error, _reason} ->
        {:error, :invalid_token}
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

  defp verify_signature({:ok, jwt_claims, _claims_grant} = result, opts) do
    api_key = Config.fetch_from_opts!(:api_key, opts)

    if jwt_claims["iss"] == api_key do
      result
    else
      {:error, :invalid_issuer}
    end
  end
end

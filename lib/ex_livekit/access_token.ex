defmodule ExLivekit.AccessToken do
  @moduledoc """
  Module for creating and managing LiveKit access tokens.

  This module provides functionality to create access tokens for LiveKit services.
  It handles token creation, grant management, and JWT encoding.

  ## Examples

  ```elixir
  token =
    ExLivekit.AccessToken.new()
    |> ExLivekit.AccessToken.add_identity("identity")
    |> ExLivekit.AccessToken.add_ttl(3600)
    |> ExLivekit.AccessToken.add_metadata("metadata")
    |> ExLivekit.AccessToken.add_name("name")
    |> ExLivekit.AccessToken.add_grants(%ExLivekit.Grants.VideoGrant{room_create: true})
    |> ExLivekit.AccessToken.to_jwt()
  ```
  """

  alias ExLivekit.Config
  alias ExLivekit.Grants.{ClaimGrant, InferenceGrant, ObservabilityGrant, SIPGrant, VideoGrant}

  @default_ttl 3600
  @participant_kinds [:standard, :egress, :ingress, :sip, :agent]

  @type api_key :: binary()
  @type api_secret :: binary()
  @type attributes :: %{String.t() => String.t()}
  @type claims :: map()
  @type jwt_token :: binary()
  @type kind :: :standard | :egress | :ingress | :sip | :agent
  @type ttl :: integer() | binary()

  defstruct [
    :api_key,
    :api_secret,
    grants: %ClaimGrant{},
    ttl: @default_ttl
  ]

  @type t :: %__MODULE__{
          api_key: api_key(),
          api_secret: api_secret(),
          grants: ClaimGrant.t(),
          ttl: ttl()
        }

  @doc """
  Creates a new access token.

  ## Examples

  If no opts are provided, it will use the api_key and api_secret from the config.
  ```elixir
  token = ExLivekit.AccessToken.new()
  ```

  ```elixir
  token = ExLivekit.AccessToken.new(api_key: "api_key", api_secret: "api_secret")
  ```
  """
  @spec new() :: t()
  @spec new(opts :: Keyword.t()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      api_key: Config.fetch_from_opts!(:api_key, opts),
      api_secret: Config.fetch_from_opts!(:api_secret, opts)
    }
  end

  @doc """
  Adds an identity to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_identity(token, "identity")
  ```
  """
  @spec add_identity(t(), binary()) :: t()
  def add_identity(%__MODULE__{} = token, identity) when is_binary(identity) do
    %{token | grants: %{token.grants | identity: identity}}
  end

  @doc """
  Adds a TTL to the token.

  default TTL is 3600 seconds.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_ttl(token, 3600)
  ```
  """
  @spec add_ttl(t(), ttl()) :: t()
  def add_ttl(%__MODULE__{} = token, ttl) when is_integer(ttl) do
    %{token | ttl: ttl}
  end

  @doc """
  Adds metadata to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_metadata(token, "metadata")
  ```
  """
  @spec add_metadata(t(), String.t()) :: t()
  def add_metadata(%__MODULE__{grants: %ClaimGrant{} = claims} = token, metadata)
      when is_binary(metadata) do
    %{token | grants: %{claims | metadata: metadata}}
  end

  @doc """
  Adds a name to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_name(token, "name")
  ```
  """
  @spec add_name(t(), String.t()) :: t()
  def add_name(%__MODULE__{grants: %ClaimGrant{} = claims} = token, name) when is_binary(name) do
    %{token | grants: %{claims | name: name}}
  end

  @doc """
  Adds video grants to the token.

  Grants can be provided as a struct or a map.
  If struct is provided it will override the existing grants.
  If map is provided it will merge with the existing grants.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_grants(token, %VideoGrant{room_create: true})
  token = ExLivekit.AccessToken.add_grants(token, %{room_create: true})
  ```
  """
  @spec add_grants(t(), VideoGrant.t() | map()) :: t()
  def add_grants(%__MODULE__{grants: %ClaimGrant{} = claims} = token, %VideoGrant{} = grant) do
    %{token | grants: %{claims | video: grant}}
  end

  def add_grants(%__MODULE__{grants: %ClaimGrant{video: nil} = claims} = token, grants)
      when is_non_struct_map(grants) do
    %{token | grants: %{claims | video: struct(VideoGrant, grants)}}
  end

  def add_grants(%__MODULE__{grants: %ClaimGrant{video: %VideoGrant{}} = claims} = token, grants)
      when is_non_struct_map(grants) do
    %{token | grants: %{claims | video: Map.merge(claims.video, grants)}}
  end

  @doc """
  Adds a kind to the token.

  kind can be one of: :standard, :egress, :ingress, :sip, :agent

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_kind(token, :standard)
  ```
  """
  @spec add_kind(t(), kind()) :: t()
  def add_kind(%__MODULE__{grants: %ClaimGrant{} = claims} = token, kind)
      when kind in @participant_kinds do
    %{token | grants: %{claims | kind: kind}}
  end

  @doc """
  Adds SIP grants to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_sip_grants(token, %SIPGrant{admin: true, call: true})
  ```
  """
  @spec add_sip_grants(t(), SIPGrant.t()) :: t()
  def add_sip_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %SIPGrant{} = sip_grants
      ) do
    %{token | grants: %{claims | sip: sip_grants}}
  end

  @doc """
  Adds inference grants to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_inference_grants(token, %InferenceGrant{perform: true})
  ```
  """
  @spec add_inference_grants(t(), InferenceGrant.t()) :: t()
  def add_inference_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %InferenceGrant{} = inference_grants
      ) do
    %{token | grants: %{claims | inference: inference_grants}}
  end

  @doc """
  Adds attributes to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_attributes(token, %{"test_attribute" => "test_value"})
  ```
  """
  @spec add_attributes(t(), attributes()) :: t()
  def add_attributes(%__MODULE__{grants: %ClaimGrant{} = claims} = token, attributes)
      when is_map(attributes) do
    %{token | grants: %{claims | attributes: attributes}}
  end

  @doc """
  Adds a room preset to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_room_preset(token, "room_preset")
  ```
  """
  @spec add_room_preset(t(), String.t()) :: t()
  def add_room_preset(%__MODULE__{grants: %ClaimGrant{} = claims} = token, room_preset)
      when is_binary(room_preset) do
    %{token | grants: %{claims | room_preset: room_preset}}
  end

  @doc """
  Adds a SHA256 to the token.

  SHA256 is used to verify the integrity of the token. And it is a hash of the payload.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_sha256(token, "sha256")
  ```
  """
  @spec add_sha256(t(), String.t()) :: t()
  def add_sha256(%__MODULE__{grants: %ClaimGrant{} = claims} = token, sha256)
      when is_binary(sha256) do
    %{token | grants: %{claims | sha256: sha256}}
  end

  @doc """
  Adds observability grants to the token.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.add_observability_grants(token, %ObservabilityGrant{write: true})
  ```
  """
  @spec add_observability_grants(t(), ObservabilityGrant.t()) :: t()
  def add_observability_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %ObservabilityGrant{} = observability_grants
      ) do
    %{token | grants: %{claims | observability: observability_grants}}
  end

  @doc """
  Converts the token to a JWT.

  ## Examples

  ```elixir
  token = ExLivekit.AccessToken.to_jwt(token)
  ```
  """
  @spec to_jwt(t()) :: binary()
  def to_jwt(%__MODULE__{} = token) do
    now = System.system_time(:second)
    exp = if is_binary(token.ttl), do: token.ttl, else: now + token.ttl
    signer = Joken.Signer.create("HS256", token.api_secret)

    jwt_claims = %{
      "sub" => token.grants.identity || "",
      "iss" => token.api_key,
      "nbf" => now,
      "exp" => exp
    }

    {:ok, jwt, _claims} =
      jwt_claims
      |> Map.merge(ClaimGrant.to_jwt_payload(token.grants))
      |> Joken.encode_and_sign(signer)

    jwt
  end
end

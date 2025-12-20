defmodule ExLivekit.AccessToken do
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

  @spec new() :: t()
  @spec new(opts :: Keyword.t()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      api_key: Config.fetch_from_opts!(:api_key, opts),
      api_secret: Config.fetch_from_opts!(:api_secret, opts)
    }
  end

  @spec add_identity(t(), binary()) :: t()
  def add_identity(%__MODULE__{} = token, identity) when is_binary(identity) do
    %{token | grants: %{token.grants | identity: identity}}
  end

  @spec add_ttl(t(), ttl()) :: t()
  def add_ttl(%__MODULE__{} = token, ttl) when is_integer(ttl) do
    %{token | ttl: ttl}
  end

  @spec add_metadata(t(), String.t()) :: t()
  def add_metadata(%__MODULE__{grants: %ClaimGrant{} = claims} = token, metadata)
      when is_binary(metadata) do
    %{token | grants: %{claims | metadata: metadata}}
  end

  @spec add_name(t(), String.t()) :: t()
  def add_name(%__MODULE__{grants: %ClaimGrant{} = claims} = token, name) when is_binary(name) do
    %{token | grants: %{claims | name: name}}
  end

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

  @spec add_kind(t(), kind()) :: t()
  def add_kind(%__MODULE__{grants: %ClaimGrant{} = claims} = token, kind)
      when kind in @participant_kinds do
    %{token | grants: %{claims | kind: kind}}
  end

  @spec add_sip_grants(t(), SIPGrant.t()) :: t()
  def add_sip_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %SIPGrant{} = sip_grants
      ) do
    %{token | grants: %{claims | sip: sip_grants}}
  end

  @spec add_inference_grants(t(), InferenceGrant.t()) :: t()
  def add_inference_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %InferenceGrant{} = inference_grants
      ) do
    %{token | grants: %{claims | inference: inference_grants}}
  end

  @spec add_attributes(t(), attributes()) :: t()
  def add_attributes(%__MODULE__{grants: %ClaimGrant{} = claims} = token, attributes)
      when is_map(attributes) do
    %{token | grants: %{claims | attributes: attributes}}
  end

  @spec add_room_preset(t(), String.t()) :: t()
  def add_room_preset(%__MODULE__{grants: %ClaimGrant{} = claims} = token, room_preset)
      when is_binary(room_preset) do
    %{token | grants: %{claims | room_preset: room_preset}}
  end

  @spec add_sha256(t(), String.t()) :: t()
  def add_sha256(%__MODULE__{grants: %ClaimGrant{} = claims} = token, sha256)
      when is_binary(sha256) do
    %{token | grants: %{claims | sha256: sha256}}
  end

  @spec add_observability_grants(t(), ObservabilityGrant.t()) :: t()
  def add_observability_grants(
        %__MODULE__{grants: %ClaimGrant{} = claims} = token,
        %ObservabilityGrant{} = observability_grants
      ) do
    %{token | grants: %{claims | observability: observability_grants}}
  end

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

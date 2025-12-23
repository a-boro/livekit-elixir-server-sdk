defmodule ExLivekit.Grants do
  defmodule VideoGrant do
    @moduledoc """
    Video grant is used to grant permissions for video related actions.

    ## Examples

    ```elixir
    video_grant = %ExLivekit.Grants.VideoGrant{room_create: true}
    ```
    """
    defstruct [
      :room_create,
      :room_list,
      :room_record,
      :room_admin,
      :room_join,
      :room,
      :destination_room,
      :can_publish_sources,
      :can_publish,
      :can_subscribe,
      :can_publish_data,
      :can_update_metadata,
      :ingress_admin,
      :hidden,
      :agent
    ]

    @type t :: %__MODULE__{
            # actions on rooms
            room_create: boolean() | nil,
            room_list: boolean() | nil,
            room_record: boolean() | nil,

            # actions on a particular room
            room_admin: boolean() | nil,
            room_join: boolean() | nil,
            room: String.t() | nil,

            # allows forwarding participant to room
            destination_room: String.t() | nil,

            # allow participant to publish. If neither canPublish or canSubscribe is set,
            # both publish and subscribe are enabled
            can_publish: boolean(),
            can_subscribe: boolean(),

            # allow participants to publish data, defaults to true if not set
            can_publish_data: boolean(),

            # TrackSource types that a participant may publish.
            # When set, it supersedes CanPublish. Only sources explicitly set here can be
            # published
            can_publish_sources: list(String.t()) | nil,

            # by default, a participant is not allowed to update its own metadata
            can_update_metadata: boolean() | nil,

            # actions on ingress
            ingress_admin: boolean() | nil,

            # participant is not visible to other participants (useful when making bots)
            hidden: boolean() | nil,

            # indicates that the holder can register as an Agent framework worker
            agent: boolean() | nil
          }
  end

  defmodule SIPGrant do
    @moduledoc """
    SIP grant is used to grant permissions for SIP related actions.

    ## Examples

    ```elixir
    sip_grant = %ExLivekit.Grants.SIPGrant{admin: true, call: true}
    ```
    """
    defstruct admin: false, call: false

    @type t :: %__MODULE__{
            # manage sip resources
            admin: boolean(),

            # make outbound calls
            call: boolean()
          }
  end

  defmodule InferenceGrant do
    @moduledoc """
    Inference grant is used to grant permissions for inference related actions.

    ## Examples

    ```elixir
    inference_grant = %ExLivekit.Grants.InferenceGrant{perform: true}
    ```
    """
    defstruct perform: false

    @type t :: %__MODULE__{
            # perform inference
            perform: boolean()
          }
  end

  defmodule ObservabilityGrant do
    @moduledoc """
    Observability grant is used to grant permissions for observability related actions.

    ## Examples

    ```elixir
    observability_grant = %ExLivekit.Grants.ObservabilityGrant{write: true}
    ```
    """
    defstruct write: false

    @type t :: %__MODULE__{
            # write grants to publish observability data
            write: boolean()
          }
  end

  defmodule ClaimGrant do
    @moduledoc """
    Claim grant are JWT claims that are used to grant permissions for a participant.
    """
    defstruct [
      :attributes,
      :identity,
      :inference,
      :kind,
      :metadata,
      :name,
      :observability,
      :room_preset,
      :sha256,
      :sip,
      :video
    ]

    @type t :: %__MODULE__{
            attributes: %{String.t() => String.t()} | nil,
            identity: binary() | nil,
            inference: InferenceGrant.t() | nil,
            kind: :standard | :egress | :ingress | :sip | :agent | nil,
            metadata: String.t() | nil,
            name: String.t() | nil,
            observability: ObservabilityGrant.t() | nil,
            room_preset: String.t() | nil,
            sha256: String.t() | nil,
            sip: SIPGrant.t() | nil,
            video: VideoGrant.t() | nil
          }

    @doc false
    @spec to_jwt_payload(t()) :: map()
    def to_jwt_payload(%__MODULE__{} = grant) do
      grant
      |> claims_to_lower_camel()
      |> Map.delete("identity")
      |> minimize_claims()
    end

    @spec claims_to_lower_camel(claims :: struct() | map()) :: map()
    defp claims_to_lower_camel(claims) when is_struct(claims) do
      claims_to_lower_camel(Map.from_struct(claims))
    end

    defp claims_to_lower_camel(claims) when is_map(claims) do
      Map.new(claims, fn
        {:attributes = k, v} ->
          {ExLivekit.Utils.snake_to_lower_camel(k), v}

        {k, v} ->
          {ExLivekit.Utils.snake_to_lower_camel(k), claims_to_lower_camel(v)}
      end)
    end

    defp claims_to_lower_camel(claims), do: claims

    # in order to produce minimal JWT size, exclude None or empty values
    @spec minimize_claims(claims :: map()) :: map()
    defp minimize_claims(claims) do
      claims
      |> Stream.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Map.new(fn {k, v} -> if is_map(v), do: {k, minimize_claims(v)}, else: {k, v} end)
    end
  end
end

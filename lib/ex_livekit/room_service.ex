defmodule ExLivekit.RoomService do
  alias ExLivekit.Client
  alias ExLivekit.Grants.VideoGrant

  alias Livekit.{
    CreateRoomRequest,
    DeleteRoomRequest,
    ForwardParticipantRequest,
    ListParticipantsRequest,
    ListParticipantsResponse,
    ListRoomsRequest,
    ListRoomsResponse,
    MoveParticipantRequest,
    MuteRoomTrackRequest,
    MuteRoomTrackResponse,
    ParticipantInfo,
    Room,
    RoomParticipantIdentity,
    SendDataRequest,
    UpdateParticipantRequest,
    UpdateRoomMetadataRequest,
    UpdateSubscriptionsRequest
  }

  @svc "RoomService"

  @type opts :: Keyword.t()
  @type room_name :: String.t()

  @spec create_room(Client.t(), room_name()) :: {:ok, Room.t()} | {:error, term()}
  @spec create_room(Client.t(), room_name(), opts()) :: {:ok, Room.t()} | {:error, term()}
  def create_room(%Client{} = client, room_name, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_create: true})

    payload =
      %CreateRoomRequest{
        name: room_name,
        room_preset: opts[:room_preset],
        empty_timeout: opts[:empty_timeout],
        departure_timeout: opts[:departure_timeout],
        max_participants: opts[:max_participants],
        node_id: opts[:node_id],
        metadata: opts[:metadata],
        egress: opts[:egress],
        min_playout_delay: opts[:min_playout_delay],
        max_playout_delay: opts[:max_playout_delay],
        sync_streams: opts[:sync_streams],
        replay_enabled: opts[:replay_enabled],
        agents: opts[:agents]
      }

    case Client.request(client, @svc, "CreateRoom", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.Room.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec list_rooms(Client.t(), opts()) :: {:ok, ListRoomsResponse.t()} | {:error, term()}
  def list_rooms(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_list: true})
    payload = %ListRoomsRequest{names: opts[:names] || []}

    case Client.request(client, @svc, "ListRooms", payload, auth_headers) do
      {:ok, body} -> {:ok, ListRoomsResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec delete_room(Client.t(), room_name()) :: :ok | {:error, term()}
  def delete_room(%Client{} = client, room_name) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_create: true})
    payload = %DeleteRoomRequest{room: room_name}

    case Client.request(client, @svc, "DeleteRoom", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec update_room_metadata(Client.t(), room_name(), String.t()) ::
          {:ok, Livekit.Room.t()} | {:error, term()}
  def update_room_metadata(%Client{} = client, room_name, metadata) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %UpdateRoomMetadataRequest{room: room_name, metadata: metadata}

    case Client.request(client, @svc, "UpdateRoomMetadata", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.Room.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec list_participants(Client.t(), room_name()) ::
          {:ok, ListParticipantsResponse.t()} | {:error, term()}
  def list_participants(%Client{} = client, room_name) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %ListParticipantsRequest{room: room_name}

    case Client.request(client, @svc, "ListParticipants", payload, auth_headers) do
      {:ok, body} -> {:ok, ListParticipantsResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec get_participant(Client.t(), room_name(), String.t()) ::
          {:ok, ParticipantInfo.t()} | {:error, term()}
  def get_participant(%Client{} = client, room_name, identity) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %RoomParticipantIdentity{room: room_name, identity: identity}

    case Client.request(client, @svc, "GetParticipant", payload, auth_headers) do
      {:ok, body} -> {:ok, ParticipantInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec remove_participant(Client.t(), room_name(), String.t()) :: :ok | {:error, term()}
  def remove_participant(%Client{} = client, room_name, identity) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %RoomParticipantIdentity{room: room_name, identity: identity}

    case Client.request(client, @svc, "RemoveParticipant", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec forward_participant(Client.t(), room_name(), String.t(), String.t()) ::
          :ok | {:error, term()}
  def forward_participant(%Client{} = client, room_name, identity, destination_room) do
    auth_headers =
      Client.auth_headers(client,
        video_grant: %VideoGrant{
          room_admin: true,
          room: room_name,
          destination_room: destination_room
        }
      )

    payload = %ForwardParticipantRequest{
      room: room_name,
      identity: identity,
      destination_room: destination_room
    }

    case Client.request(client, @svc, "ForwardParticipant", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec move_participant(Client.t(), room_name(), String.t(), String.t()) ::
          :ok | {:error, term()}
  def move_participant(%Client{} = client, room_name, identity, destination_room) do
    auth_headers =
      Client.auth_headers(client,
        video_grant: %VideoGrant{
          room_admin: true,
          room: room_name,
          destination_room: destination_room
        }
      )

    payload = %MoveParticipantRequest{
      room: room_name,
      identity: identity,
      destination_room: destination_room
    }

    case Client.request(client, @svc, "MoveParticipant", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec mute_published_track(Client.t(), room_name(), String.t(), String.t(), boolean()) ::
          {:ok, Livekit.TrackInfo.t()} | {:error, term()}
  def mute_published_track(%Client{} = client, room_name, identity, track_sid, muted) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %MuteRoomTrackRequest{
      room: room_name,
      identity: identity,
      track_sid: track_sid,
      muted: muted
    }

    case Client.request(client, @svc, "MutePublishedTrack", payload, auth_headers) do
      {:ok, body} -> {:ok, MuteRoomTrackResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec update_participant(Client.t(), room_name(), String.t(), opts()) ::
          {:ok, ParticipantInfo.t()} | {:error, term()}
  def update_participant(%Client{} = client, room_name, identity, opts \\ []) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    attributes =
      if is_map(opts[:attributes]) do
        Map.new(opts[:attributes], fn {key, value} -> {to_string(key), to_string(value)} end)
      else
        nil
      end

    payload = %UpdateParticipantRequest{
      room: room_name,
      identity: identity,
      metadata: opts[:metadata],
      permission: opts[:permission],
      name: opts[:name],
      attributes: attributes
    }

    case Client.request(client, @svc, "UpdateParticipant", payload, auth_headers) do
      {:ok, body} -> {:ok, ParticipantInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec update_subscriptions(Client.t(), room_name(), String.t(), opts()) ::
          :ok | {:error, term()}
  def update_subscriptions(%Client{} = client, room_name, identity, opts \\ []) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %UpdateSubscriptionsRequest{
      room: room_name,
      identity: identity,
      track_sids: opts[:track_sids],
      subscribe: opts[:subscribe],
      participant_tracks: opts[:participant_tracks]
    }

    case Client.request(client, @svc, "UpdateSubscriptions", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec send_data(Client.t(), room_name(), binary(), Livekit.DataPacket.Kind.t(), opts()) ::
          :ok | {:error, term()}
  def send_data(%Client{} = client, room_name, data, kind, opts \\ []) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %SendDataRequest{
      room: room_name,
      data: data,
      kind: kind,
      destination_identities: Keyword.get(opts, :destination_identities, []),
      topic: Keyword.get(opts, :topic, nil),
      nonce: :crypto.strong_rand_bytes(16)
    }

    case Client.request(client, @svc, "SendData", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end

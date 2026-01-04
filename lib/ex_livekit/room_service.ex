defmodule ExLivekit.RoomService do
  @moduledoc """
  Module for interacting with the LiveKit Room Service.

  This module provides functionality to create, list, delete, and update rooms, as well as manage participants and subscriptions.
  """

  alias ExLivekit.Client
  alias ExLivekit.Client.Error
  alias ExLivekit.Grants.VideoGrant

  alias Livekit.{
    CreateRoomRequest,
    DeleteRoomRequest,
    ForwardParticipantRequest,
    ListParticipantsRequest,
    ListRoomsRequest,
    MoveParticipantRequest,
    MuteRoomTrackRequest,
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
  @type participant_identity :: String.t()

  @type create_room_opts :: [
          room_preset: String.t(),
          empty_timeout: integer(),
          departure_timeout: integer(),
          max_participants: integer(),
          node_id: String.t(),
          metadata: String.t(),
          egress: Livekit.RoomEgress.t(),
          min_playout_delay: integer(),
          max_playout_delay: integer(),
          sync_streams: boolean(),
          replay_enabled: boolean(),
          agents: [Livekit.RoomAgentDispatch.t()]
        ]

  @doc """
  Creates a new room.

  Options:
  - room_preset: the preset to use for the room
  - empty_timeout: the timeout for the room to be empty in seconds
  - departure_timeout: the timeout for the room to be departed in seconds
  - max_participants: the maximum number of participants in the room
  - node_id: the node id to use for the room creation. Only for advanced users.
  - metadata: the metadata to use for the room
  - egress: the egress to use for the room. See `Livekit.RoomEgress` for more information
  - min_playout_delay: the minimum playout delay for the room in milliseconds
  - max_playout_delay: the maximum playout delay for the room in milliseconds
  - sync_streams: whether to sync streams for the room
  - replay_enabled: whether to enable replay for the room
  - agents: the agents to use for the room. See `Livekit.RoomAgent` for more information

  ## Examples

  ```elixir
  {:ok, room} = ExLivekit.RoomService.create_room(client, "room_name")
  {:ok, room} = ExLivekit.RoomService.create_room(client, "room_name",
    room_preset: "high",
    empty_timeout: 10,
    departure_timeout: 20,
    max_participants: 10,
    node_id: "test_node",
    metadata: "test_metadata",
    agents: [%Livekit.RoomAgentDispatch{agent_name: "agent_name", metadata: "metadata"}]
  )
  ```

  """
  @spec create_room(Client.t(), room_name()) :: {:ok, Room.t()} | {:error, Error.t()}
  @spec create_room(Client.t(), room_name(), create_room_opts()) ::
          {:ok, Room.t()} | {:error, Error.t()}
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

  @type list_rooms_opts :: [
          names: [room_name()]
        ]
  @doc """
  Lists rooms that are active on the server.

  Options:
  - names: list of room names to filter by

  ## Examples

  ```elixir
  {:ok, rooms} = ExLivekit.RoomService.list_rooms(client)
  {:ok, rooms} = ExLivekit.RoomService.list_rooms(client, names: ["room1", "room2"])
  ```
  """
  @spec list_rooms(Client.t(), list_rooms_opts()) ::
          {:ok, [Room.t()]} | {:error, Error.t()}
  def list_rooms(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_list: true})
    payload = %ListRoomsRequest{names: Keyword.get(opts, :names, [])}

    case Client.request(client, @svc, "ListRooms", payload, auth_headers) do
      {:ok, body} ->
        resp = Livekit.ListRoomsResponse.decode(body)
        {:ok, resp.rooms}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Deletes an existing room by name or id.

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.delete_room(client, "room_name")
  ```
  """
  @spec delete_room(Client.t(), room_name()) :: :ok | {:error, Error.t()}
  def delete_room(%Client{} = client, room_name) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_create: true})
    payload = %DeleteRoomRequest{room: room_name}

    case Client.request(client, @svc, "DeleteRoom", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Updates the metadata of a room.

  ## Examples

  ```elixir
  {:ok, room} = ExLivekit.RoomService.update_room_metadata(client, "room_name", "new_metadata")
  ```
  """
  @spec update_room_metadata(Client.t(), room_name(), String.t()) ::
          {:ok, Livekit.Room.t()} | {:error, Error.t()}
  def update_room_metadata(%Client{} = client, room_name, metadata) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %UpdateRoomMetadataRequest{room: room_name, metadata: metadata}

    case Client.request(client, @svc, "UpdateRoomMetadata", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.Room.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Lists participants in a room.

  ## Examples

  ```elixir
  {:ok, participants} = ExLivekit.RoomService.list_participants(client, "room_name")
  ```
  """
  @spec list_participants(Client.t(), room_name()) ::
          {:ok, [ParticipantInfo.t()]} | {:error, Error.t()}
  def list_participants(%Client{} = client, room_name) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %ListParticipantsRequest{room: room_name}

    case Client.request(client, @svc, "ListParticipants", payload, auth_headers) do
      {:ok, body} ->
        resp = Livekit.ListParticipantsResponse.decode(body)
        {:ok, resp.participants}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Gets information on a specific participant in a room.

  ## Examples

  ```elixir
  {:ok, participant} = ExLivekit.RoomService.get_participant(client, "room_name", "participant_identity")
  ```
  """
  @spec get_participant(Client.t(), room_name(), participant_identity()) ::
          {:ok, ParticipantInfo.t()} | {:error, Error.t()}
  def get_participant(%Client{} = client, room_name, identity) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %RoomParticipantIdentity{room: room_name, identity: identity}

    case Client.request(client, @svc, "GetParticipant", payload, auth_headers) do
      {:ok, body} -> {:ok, ParticipantInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Removes a participant from a room.

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.remove_participant(client, "room_name", "participant_identity")
  ```
  """
  @spec remove_participant(Client.t(), room_name(), participant_identity()) ::
          :ok | {:error, Error.t()}
  def remove_participant(%Client{} = client, room_name, identity) do
    auth_headers =
      Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})

    payload = %RoomParticipantIdentity{room: room_name, identity: identity}

    case Client.request(client, @svc, "RemoveParticipant", payload, auth_headers) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Forwards a participant from one room to another.
  Available in LiveKit Cloud only.

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.forward_participant(client, "room_name", "participant_identity", "destination_room")
  ```
  """
  @spec forward_participant(Client.t(), room_name(), participant_identity(), room_name()) ::
          :ok | {:error, Error.t()}
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

  @doc """
  Moves a participant from one room to another.
  Available in LiveKit Cloud only.

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.move_participant(client, "room_name", "participant_identity", "destination_room")
  ```
  """
  @spec move_participant(Client.t(), room_name(), participant_identity(), room_name()) ::
          :ok | {:error, Error.t()}
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

  @doc """
  Mutes a published track for a participant in a room.

  ## Examples

  ```elixir
  {:ok, track} = ExLivekit.RoomService.mute_published_track(client, "room_name", "participant_identity", "track_sid", true)
  ```
  """
  @spec mute_published_track(
          Client.t(),
          room_name(),
          participant_identity(),
          binary(),
          boolean()
        ) ::
          {:ok, Livekit.TrackInfo.t() | nil} | {:error, Error.t()}
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
      {:ok, body} ->
        resp = Livekit.MuteRoomTrackResponse.decode(body)
        {:ok, resp.track}

      {:error, error} ->
        {:error, error}
    end
  end

  @type update_participant_opts :: [
          metadata: String.t(),
          permission: Livekit.ParticipantPermission.t(),
          name: String.t(),
          attributes: map()
        ]
  @doc """
  Updates the metadata of a participant in a room.

  Options:
  - metadata: the metadata to update
  - permission: the permission to update
  - name: the name to update
  - attributes: the attributes to update

  ## Examples

  ```elixir
  {:ok, participant} = ExLivekit.RoomService.update_participant(client, "room_name", "participant_identity", "new_metadata")

  {:ok, participant} = ExLivekit.RoomService.update_participant(client, "room_name", "participant_identity",
    metadata: "new_metadata",
    permission: %Livekit.ParticipantPermission{can_subscribe: true, can_publish: true, can_publish_data: true},
    name: "new_name",
    attributes: %{key1: "value1", key2: "value2"}
  )
  ```
  """
  @spec update_participant(
          Client.t(),
          room_name(),
          participant_identity(),
          update_participant_opts()
        ) ::
          {:ok, ParticipantInfo.t()} | {:error, Error.t()}
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

  @type update_subscriptions_opts :: [
          track_sids: [String.t()],
          subscribe: boolean(),
          participant_tracks: [Livekit.ParticipantTracks.t()]
        ]

  @doc """
  Updates the subscriptions of a participant in a room.

  Options:
  - track_sids: list of track sids to subscribe to
  - subscribe: true to subscribe, false to unsubscribe
  - participant_tracks: list of participant tracks to subscribe to

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.update_subscriptions(client, "room_name", "participant_identity", "track_sid")
  ```
  """
  @spec update_subscriptions(
          Client.t(),
          room_name(),
          participant_identity(),
          update_subscriptions_opts()
        ) ::
          :ok | {:error, Error.t()}
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

  @type send_data_opts :: [
          destination_identities: [participant_identity()],
          topic: String.t()
        ]
  @doc """
  Sends data to a room.

  Options:
  - destination_identities: list of identities to send the data to
  - topic: topic to send the data to

  ## Examples

  ```elixir
  :ok = ExLivekit.RoomService.send_data(client, "room_name", "data", :RELIABLE, destination_identities: ["identity1", "identity2"], topic: "topic")
  ```
  """
  @spec send_data(
          Client.t(),
          room_name(),
          data :: binary(),
          kind :: :RELIABLE | :LOSSY,
          send_data_opts()
        ) ::
          :ok | {:error, Error.t()}
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

defmodule ExLivekit.RoomServiceTest do
  use ExUnit.Case

  alias ExLivekit.RoomService

  setup do
    bypass = Bypass.open()

    client =
      ExLivekit.Client.new(
        host: "http://localhost:#{bypass.port}",
        api_key: "test_key",
        api_secret: "test_secret"
      )

    {:ok, bypass: bypass, client: client}
  end

  describe "create_room/2" do
    @url "/twirp/livekit.RoomService/CreateRoom"
    test "creates a room", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateRoomRequest.decode() |> Map.from_struct()
        response = struct(Livekit.Room, request) |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, room} = RoomService.create_room(client, "test_room")
      assert room.name == "test_room"
    end

    test "creates a room with options", %{bypass: bypass, client: client} do
      opts = [
        room_preset: "high",
        empty_timeout: 10,
        departure_timeout: 20,
        max_participants: 10,
        node_id: "test_node",
        metadata: "test_metadata",
        min_playout_delay: 100,
        max_playout_delay: 200,
        sync_streams: true,
        replay_enabled: true
      ]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateRoomRequest.decode() |> Map.from_struct()

        assert request.room_preset == "high"
        assert request.node_id == opts[:node_id]
        assert request.metadata == opts[:metadata]
        assert request.min_playout_delay == opts[:min_playout_delay]
        assert request.max_playout_delay == opts[:max_playout_delay]
        assert request.sync_streams == opts[:sync_streams]
        assert request.replay_enabled == opts[:replay_enabled]

        response = struct(Livekit.Room, request) |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, room} = RoomService.create_room(client, "test_room", opts)

      assert room.name == "test_room"
      assert room.empty_timeout == 10
      assert room.departure_timeout == 20
      assert room.max_participants == 10
      assert room.metadata == "test_metadata"
    end
  end

  describe "list_rooms/2" do
    @url "/twirp/livekit.RoomService/ListRooms"
    test "lists all rooms", %{bypass: bypass, client: client} do
      room1 = %Livekit.Room{name: "room1", sid: "sid1"}
      room2 = %Livekit.Room{name: "room2", sid: "sid2"}

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListRoomsRequest.decode() |> Map.from_struct()

        assert request.names == []

        response =
          %Livekit.ListRoomsResponse{rooms: [room1, room2]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      {:ok, response} = RoomService.list_rooms(client)
      assert length(response.rooms) == 2
      assert Enum.at(response.rooms, 0).name == "room1"
      assert Enum.at(response.rooms, 1).name == "room2"
    end

    test "lists rooms with names filter", %{bypass: bypass, client: client} do
      room1 = %Livekit.Room{name: "room1", sid: "sid1"}

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListRoomsRequest.decode() |> Map.from_struct()

        assert request.names == ["room1", "room2"]

        response =
          %Livekit.ListRoomsResponse{rooms: [room1]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.ListRoomsResponse{rooms: [%Livekit.Room{name: "room1"}]}} =
               RoomService.list_rooms(client, names: ["room1", "room2"])
    end
  end

  describe "delete_room/2" do
    @url "/twirp/livekit.RoomService/DeleteRoom"
    test "deletes a room", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.DeleteRoomRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"

        response = %Livekit.DeleteRoomResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert RoomService.delete_room(client, "test_room") == :ok
    end
  end

  describe "update_room_metadata/3" do
    @url "/twirp/livekit.RoomService/UpdateRoomMetadata"
    test "updates room metadata", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateRoomMetadataRequest.decode() |> Map.from_struct()

        response =
          %Livekit.Room{name: request.room, metadata: request.metadata}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.Room{name: "test_room", metadata: "updated_metadata"}} =
               RoomService.update_room_metadata(client, "test_room", "updated_metadata")
    end
  end

  describe "list_participants/2" do
    @url "/twirp/livekit.RoomService/ListParticipants"
    test "lists participants in a room", %{bypass: bypass, client: client} do
      participant1 = %Livekit.ParticipantInfo{
        sid: "sid1",
        identity: "user1",
        name: "User 1"
      }

      participant2 = %Livekit.ParticipantInfo{
        sid: "sid2",
        identity: "user2",
        name: "User 2"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListParticipantsRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"

        response =
          %Livekit.ListParticipantsResponse{participants: [participant1, participant2]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.ListParticipantsResponse{participants: participants}} =
               RoomService.list_participants(client, "test_room")

      assert length(participants) == 2
      assert Enum.at(participants, 0).identity == "user1"
      assert Enum.at(participants, 1).identity == "user2"
    end
  end

  describe "get_participant/3" do
    @url "/twirp/livekit.RoomService/GetParticipant"
    test "gets a participant", %{bypass: bypass, client: client} do
      participant = %Livekit.ParticipantInfo{
        sid: "sid1",
        identity: "user1",
        name: "User 1",
        metadata: "test_metadata"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.RoomParticipantIdentity.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"

        response = participant |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.ParticipantInfo{identity: "user1", name: "User 1"}} =
               RoomService.get_participant(client, "test_room", "user1")
    end
  end

  describe "remove_participant/3" do
    @url "/twirp/livekit.RoomService/RemoveParticipant"
    test "removes a participant", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.RoomParticipantIdentity.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"

        response = %Livekit.RemoveParticipantResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert RoomService.remove_participant(client, "test_room", "user1") == :ok
    end
  end

  describe "forward_participant/4" do
    @url "/twirp/livekit.RoomService/ForwardParticipant"
    test "forwards a participant", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ForwardParticipantRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert request.destination_room == "dest_room"

        response = %Livekit.ForwardParticipantResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert RoomService.forward_participant(client, "test_room", "user1", "dest_room") == :ok
    end
  end

  describe "move_participant/4" do
    @url "/twirp/livekit.RoomService/MoveParticipant"
    test "moves a participant", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.MoveParticipantRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert request.destination_room == "dest_room"

        response = %Livekit.MoveParticipantResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert RoomService.move_participant(client, "test_room", "user1", "dest_room") == :ok
    end
  end

  describe "mute_published_track/5" do
    @url "/twirp/livekit.RoomService/MutePublishedTrack"
    test "mutes a published track", %{bypass: bypass, client: client} do
      track = %Livekit.TrackInfo{
        sid: "track_sid1",
        name: "track1",
        muted: true
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.MuteRoomTrackRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert request.track_sid == "track_sid1"
        assert request.muted == true

        response = %Livekit.MuteRoomTrackResponse{track: track} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.MuteRoomTrackResponse{track: %Livekit.TrackInfo{muted: true}}} =
               RoomService.mute_published_track(client, "test_room", "user1", "track_sid1", true)
    end
  end

  describe "update_participant/4" do
    @url "/twirp/livekit.RoomService/UpdateParticipant"
    test "updates a participant", %{bypass: bypass, client: client} do
      participant = %Livekit.ParticipantInfo{
        sid: "sid1",
        identity: "user1",
        name: "Updated Name",
        metadata: "updated_metadata"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateParticipantRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert request.name == "Updated Name"
        assert request.metadata == "updated_metadata"

        response = participant |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      opts = [name: "Updated Name", metadata: "updated_metadata"]

      assert {:ok, %Livekit.ParticipantInfo{name: "Updated Name", metadata: "updated_metadata"}} =
               RoomService.update_participant(client, "test_room", "user1", opts)
    end

    test "updates a participant with attributes", %{bypass: bypass, client: client} do
      participant = %Livekit.ParticipantInfo{
        sid: "sid1",
        identity: "user1",
        attributes: %{"key1" => "value1", "key2" => "value2"}
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateParticipantRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"

        # Attributes are converted to a map with string keys
        assert is_map(request.attributes)
        assert request.attributes["key1"] == "value1"
        assert request.attributes["key2"] == "value2"

        response = participant |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      opts = [attributes: %{key1: "value1", key2: "value2"}]

      assert {:ok, %Livekit.ParticipantInfo{}} =
               RoomService.update_participant(client, "test_room", "user1", opts)
    end
  end

  describe "update_subscriptions/4" do
    @url "/twirp/livekit.RoomService/UpdateSubscriptions"
    test "updates subscriptions", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateSubscriptionsRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert request.track_sids == ["track1", "track2"]
        assert request.subscribe == true

        response = %Livekit.UpdateSubscriptionsResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      opts = [track_sids: ["track1", "track2"], subscribe: true]

      assert RoomService.update_subscriptions(client, "test_room", "user1", opts) == :ok
    end

    test "updates subscriptions with participant tracks", %{bypass: bypass, client: client} do
      participant_tracks = %Livekit.ParticipantTracks{
        participant_sid: "participant_sid1",
        track_sids: ["track1", "track2"]
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateSubscriptionsRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.identity == "user1"
        assert length(request.participant_tracks) == 1
        assert Enum.at(request.participant_tracks, 0).participant_sid == "participant_sid1"

        response = %Livekit.UpdateSubscriptionsResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      opts = [participant_tracks: [participant_tracks]]

      assert RoomService.update_subscriptions(client, "test_room", "user1", opts) == :ok
    end
  end

  describe "send_data/5" do
    @url "/twirp/livekit.RoomService/SendData"
    test "sends data", %{bypass: bypass, client: client} do
      data = "test data"
      kind = :RELIABLE

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.SendDataRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.data == data
        assert request.kind == :RELIABLE
        assert request.destination_identities == []
        assert is_nil(request.topic)
        assert byte_size(request.nonce) == 16

        response = %Livekit.SendDataResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert RoomService.send_data(client, "test_room", data, kind) == :ok
    end

    test "sends data with options", %{bypass: bypass, client: client} do
      data = "test data"
      kind = :LOSSY

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.SendDataRequest.decode() |> Map.from_struct()

        assert request.room == "test_room"
        assert request.data == data
        assert request.kind == :LOSSY
        assert request.destination_identities == ["user1", "user2"]
        assert request.topic == "test_topic"

        response = %Livekit.SendDataResponse{} |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      opts = [destination_identities: ["user1", "user2"], topic: "test_topic"]

      assert RoomService.send_data(client, "test_room", data, kind, opts) == :ok
    end
  end
end

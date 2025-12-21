defmodule ExLivekit.AgentDispatchServiceTest do
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  use ExUnit.Case
  alias ExLivekit.AgentDispatchService

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

  describe "create_dispatch/4" do
    @url "/twirp/livekit.AgentDispatchService/CreateDispatch"
    test "creates a dispatch", %{bypass: bypass, client: client} do
      room_name = "test_room"
      agent_name = "test_agent"
      dispatch_id = "dispatch_123"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateAgentDispatchRequest.decode() |> Map.from_struct()

        response =
          %Livekit.AgentDispatch{
            id: dispatch_id,
            agent_name: request.agent_name,
            room: request.room,
            metadata: request.metadata
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok,
              %Livekit.AgentDispatch{
                id: ^dispatch_id,
                agent_name: ^agent_name,
                room: ^room_name,
                metadata: ""
              }} =
               AgentDispatchService.create_dispatch(client, room_name, agent_name)
    end

    test "creates a dispatch with metadata", %{bypass: bypass, client: client} do
      room_name = "test_room"
      agent_name = "test_agent"
      metadata = "test_metadata"
      dispatch_id = "dispatch_456"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateAgentDispatchRequest.decode() |> Map.from_struct()

        response =
          %Livekit.AgentDispatch{
            id: dispatch_id,
            agent_name: request.agent_name,
            room: request.room,
            metadata: request.metadata
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok,
              %Livekit.AgentDispatch{
                id: ^dispatch_id,
                metadata: ^metadata,
                room: ^room_name,
                agent_name: ^agent_name
              }} =
               AgentDispatchService.create_dispatch(client, room_name, agent_name, metadata)
    end
  end

  describe "delete_dispatch/3" do
    @url "/twirp/livekit.AgentDispatchService/DeleteDispatch"
    test "deletes a dispatch", %{bypass: bypass, client: client} do
      dispatch_id = "dispatch_789"
      room_name = "test_room"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.DeleteAgentDispatchRequest.decode() |> Map.from_struct()

        response =
          %Livekit.AgentDispatch{
            id: dispatch_id,
            room: request.room
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.AgentDispatch{id: ^dispatch_id, room: ^room_name}} =
               AgentDispatchService.delete_dispatch(client, dispatch_id, room_name)
    end
  end

  describe "get_dispatch/3" do
    @url "/twirp/livekit.AgentDispatchService/GetDispatch"
    test "gets a dispatch", %{bypass: bypass, client: client} do
      dispatch_id = "dispatch_101"
      room_name = "test_room"

      dispatch = %Livekit.AgentDispatch{
        id: dispatch_id,
        agent_name: "test_agent",
        room: room_name,
        metadata: "test_metadata"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListAgentDispatchRequest.decode() |> Map.from_struct()

        assert request.dispatch_id == dispatch_id
        assert request.room == room_name

        response =
          %Livekit.ListAgentDispatchResponse{agent_dispatches: [dispatch]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.AgentDispatch{id: ^dispatch_id}} =
               AgentDispatchService.get_dispatch(client, dispatch_id, room_name)
    end

    test "returns nil when dispatch not found", %{bypass: bypass, client: client} do
      dispatch_id = "dispatch_not_found"
      room_name = "test_room"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListAgentDispatchRequest.decode() |> Map.from_struct()

        assert request.dispatch_id == dispatch_id
        assert request.room == room_name

        response =
          %Livekit.ListAgentDispatchResponse{agent_dispatches: []}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, nil} = AgentDispatchService.get_dispatch(client, dispatch_id, room_name)
    end
  end

  describe "list_dispatch/2" do
    @url "/twirp/livekit.AgentDispatchService/ListDispatch"
    test "lists all dispatches for a room", %{bypass: bypass, client: client} do
      room_name = "test_room"

      dispatch1 = %Livekit.AgentDispatch{
        id: "dispatch_1",
        agent_name: "agent1",
        room: room_name,
        metadata: "metadata1"
      }

      dispatch2 = %Livekit.AgentDispatch{
        id: "dispatch_2",
        agent_name: "agent2",
        room: room_name,
        metadata: "metadata2"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListAgentDispatchRequest.decode() |> Map.from_struct()

        assert request.room == room_name
        assert request.dispatch_id == ""

        response =
          %Livekit.ListAgentDispatchResponse{agent_dispatches: [dispatch1, dispatch2]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.ListAgentDispatchResponse{agent_dispatches: dispatches}} =
               AgentDispatchService.list_dispatch(client, room_name)

      assert length(dispatches) == 2
      assert Enum.at(dispatches, 0).id == "dispatch_1"
      assert Enum.at(dispatches, 1).id == "dispatch_2"
    end

    test "returns empty list when no dispatches found", %{bypass: bypass, client: client} do
      room_name = "empty_room"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListAgentDispatchRequest.decode() |> Map.from_struct()

        assert request.room == room_name
        assert request.dispatch_id == ""

        response =
          %Livekit.ListAgentDispatchResponse{agent_dispatches: []}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.ListAgentDispatchResponse{agent_dispatches: []}} =
               AgentDispatchService.list_dispatch(client, room_name)
    end
  end
end

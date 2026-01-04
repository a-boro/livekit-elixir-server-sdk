defmodule ExLivekit.IngressServiceTest do
  use ExUnit.Case
  alias ExLivekit.IngressService

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

  describe "create_ingress/2" do
    @url "/twirp/livekit.Ingress/CreateIngress"
    test "creates an ingress", %{bypass: bypass, client: client} do
      ingress_id = "ingress_123"
      opts = [input_type: :RTMP_INPUT, room_name: "test_room"]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateIngressRequest.decode() |> Map.from_struct()

        assert request.input_type == opts[:input_type]
        assert request.room_name == opts[:room_name]

        response =
          %Livekit.IngressInfo{
            ingress_id: ingress_id,
            room_name: request.room_name,
            input_type: request.input_type
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.IngressInfo{} = response} =
               IngressService.create_ingress(client, opts)

      assert response.ingress_id == ingress_id
      assert response.room_name == opts[:room_name]
      assert response.input_type == opts[:input_type]
    end

    test "creates an ingress with all options", %{bypass: bypass, client: client} do
      ingress_id = "ingress_123"

      opts = [
        input_type: :URL_INPUT,
        name: "test_ingress",
        room_name: "test_room",
        participant_identity: "participant1",
        participant_name: "Participant 1",
        url: "https://example.com/stream.mp4",
        enable_transcoding: true
      ]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.CreateIngressRequest.decode() |> Map.from_struct()

        assert request.input_type == opts[:input_type]
        assert request.name == opts[:name]
        assert request.room_name == opts[:room_name]
        assert request.participant_identity == opts[:participant_identity]
        assert request.participant_name == opts[:participant_name]
        assert request.enable_transcoding == opts[:enable_transcoding]

        response =
          %Livekit.IngressInfo{
            ingress_id: ingress_id,
            name: request.name,
            room_name: request.room_name,
            participant_identity: request.participant_identity,
            participant_name: request.participant_name,
            url: request.url,
            input_type: request.input_type
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.IngressInfo{} = response} =
               IngressService.create_ingress(client, opts)

      assert response.ingress_id == ingress_id
      assert response.name == opts[:name]
      assert response.input_type == opts[:input_type]
      assert response.room_name == opts[:room_name]
      assert response.participant_identity == opts[:participant_identity]
      assert response.participant_name == opts[:participant_name]
      assert response.url == opts[:url]
    end
  end

  describe "update_ingress/2" do
    @url "/twirp/livekit.Ingress/UpdateIngress"
    test "updates an ingress", %{bypass: bypass, client: client} do
      ingress_id = "ingress_123"
      opts = [name: "updated_ingress", room_name: "test_room"]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateIngressRequest.decode() |> Map.from_struct()

        assert request.ingress_id == ingress_id
        assert request.name == opts[:name]
        assert request.room_name == opts[:room_name]

        response =
          %Livekit.IngressInfo{
            ingress_id: request.ingress_id,
            name: request.name,
            room_name: request.room_name
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.IngressInfo{} = response} =
               IngressService.update_ingress(client, ingress_id, opts)

      assert response.ingress_id == ingress_id
      assert response.name == opts[:name]
      assert response.room_name == opts[:room_name]
    end

    test "updates an ingress with participant options", %{bypass: bypass, client: client} do
      ingress_id = "ingress_123"

      opts = [
        name: "updated_ingress",
        room_name: "test_room",
        participant_identity: "participant1",
        participant_name: "Updated Participant"
      ]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateIngressRequest.decode() |> Map.from_struct()

        assert request.name == opts[:name]
        assert request.room_name == opts[:room_name]
        assert request.participant_identity == opts[:participant_identity]
        assert request.participant_name == opts[:participant_name]

        response =
          %Livekit.IngressInfo{
            ingress_id: request.ingress_id,
            name: request.name,
            room_name: request.room_name,
            participant_identity: request.participant_identity,
            participant_name: request.participant_name
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.IngressInfo{} = response} =
               IngressService.update_ingress(client, ingress_id, opts)

      assert response.ingress_id == ingress_id
      assert response.name == opts[:name]
      assert response.room_name == opts[:room_name]
      assert response.participant_identity == opts[:participant_identity]
      assert response.participant_name == opts[:participant_name]
    end
  end

  describe "list_ingresses/2" do
    @url "/twirp/livekit.Ingress/ListIngress"
    test "lists all ingresses", %{bypass: bypass, client: client} do
      ingress1 = %Livekit.IngressInfo{
        ingress_id: "ingress_1",
        name: "ingress1",
        room_name: "room1"
      }

      ingress2 = %Livekit.IngressInfo{
        ingress_id: "ingress_2",
        name: "ingress2",
        room_name: "room2"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListIngressRequest.decode() |> Map.from_struct()

        assert request.room_name == ""
        assert request.ingress_id == ""

        response =
          %Livekit.ListIngressResponse{items: [ingress1, ingress2]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, items} = IngressService.list_ingresses(client)

      assert length(items) == 2
      assert Enum.at(items, 0).ingress_id == "ingress_1"
      assert Enum.at(items, 1).ingress_id == "ingress_2"
    end

    test "lists ingresses filtered by room_name", %{bypass: bypass, client: client} do
      ingress = %Livekit.IngressInfo{
        ingress_id: "ingress_1",
        name: "ingress1",
        room_name: "test_room"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListIngressRequest.decode() |> Map.from_struct()

        assert request.room_name == "test_room"
        assert request.ingress_id == ""

        response =
          %Livekit.ListIngressResponse{items: [ingress]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, [%Livekit.IngressInfo{room_name: "test_room"}]} =
               IngressService.list_ingresses(client, room_name: "test_room")
    end

    test "lists ingresses filtered by ingress_id", %{bypass: bypass, client: client} do
      ingress_id = "ingress_123"

      ingress = %Livekit.IngressInfo{
        ingress_id: ingress_id,
        name: "ingress1"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListIngressRequest.decode() |> Map.from_struct()

        assert request.ingress_id == ingress_id
        assert request.room_name == ""

        response =
          %Livekit.ListIngressResponse{items: [ingress]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, [%Livekit.IngressInfo{ingress_id: ^ingress_id}]} =
               IngressService.list_ingresses(client, ingress_id: ingress_id)
    end
  end

  describe "delete_ingress/2" do
    @url "/twirp/livekit.Ingress/DeleteIngress"
    test "deletes an ingress", %{bypass: bypass, client: client} do
      ingress = %Livekit.IngressInfo{
        ingress_id: "ingress_123",
        name: "test_ingress"
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.DeleteIngressRequest.decode() |> Map.from_struct()

        assert request.ingress_id == "ingress_123"

        response = ingress |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.IngressInfo{ingress_id: "ingress_123", name: "test_ingress"}} =
               IngressService.delete_ingress(client, "ingress_123")
    end
  end
end

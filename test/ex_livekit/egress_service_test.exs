defmodule ExLivekit.EgressServiceTest do
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  use ExUnit.Case
  alias ExLivekit.EgressService

  alias Livekit.{
    DirectFileOutput,
    EncodedFileOutput,
    EncodingOptions,
    ImageOutput,
    ParticipantEgressRequest,
    RoomCompositeEgressRequest,
    SegmentedFileOutput,
    StreamOutput,
    TrackCompositeEgressRequest,
    WebEgressRequest
  }

  defp base_request do
    %RoomCompositeEgressRequest{
      room_name: "test_room",
      audio_only: false
    }
  end

  defp bypass_client do
    bypass = Bypass.open()

    client =
      ExLivekit.Client.new(
        host: "http://localhost:#{bypass.port}",
        api_key: "test_key",
        api_secret: "test_secret"
      )

    {:ok, bypass: bypass, client: client}
  end

  describe "start_room_composite_egress/4" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StartRoomCompositeEgress"
    test "starts room composite egress", %{bypass: bypass, client: client} do
      room_name = "test_room"
      output = %EncodedFileOutput{filepath: "test.mp4", file_type: :MP4}
      egress_id = "egress_123"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.RoomCompositeEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert length(request.file_outputs) == 1
        assert Enum.at(request.file_outputs, 0).filepath == "test.mp4"

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id, room_name: ^room_name}} =
               EgressService.start_room_composite_egress(client, room_name, output)
    end

    test "starts room composite egress with options", %{bypass: bypass, client: client} do
      room_name = "test_room"
      output = %StreamOutput{protocol: :RTMP, urls: ["rtmp://example.com/live"]}

      opts = [
        layout: "grid",
        audio_only: true,
        video_only: false,
        custom_base_url: "https://example.com"
      ]

      egress_id = "egress_456"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.RoomCompositeEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.layout == opts[:layout]
        assert request.audio_only == opts[:audio_only]
        assert request.video_only == opts[:video_only]
        assert request.custom_base_url == opts[:custom_base_url]
        assert length(request.stream_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_room_composite_egress(client, room_name, output, opts)
    end
  end

  describe "start_participant_egress/4" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StartParticipantEgress"
    test "starts participant egress", %{bypass: bypass, client: client} do
      room_name = "test_room"
      identity = "participant1"
      output = %EncodedFileOutput{filepath: "participant.mp4", file_type: :MP4}
      egress_id = "egress_789"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ParticipantEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.identity == identity
        assert request.screen_share == false
        assert length(request.file_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id, room_name: ^room_name}} =
               EgressService.start_participant_egress(client, room_name, identity, output)
    end

    test "starts participant egress with screen share", %{bypass: bypass, client: client} do
      room_name = "test_room"
      identity = "participant1"
      output = %StreamOutput{protocol: :RTMP, urls: ["rtmp://example.com/live"]}
      opts = [screen_share: true]
      egress_id = "egress_101"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ParticipantEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.identity == identity
        assert request.screen_share == true
        assert length(request.stream_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_participant_egress(client, room_name, identity, output, opts)
    end
  end

  describe "start_track_composite_egress/3" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StartTrackCompositeEgress"
    test "starts track composite egress", %{bypass: bypass, client: client} do
      room_name = "test_room"

      output = %SegmentedFileOutput{
        filename_prefix: "track",
        playlist_name: "playlist.m3u8",
        protocol: :HLS_PROTOCOL
      }

      egress_id = "egress_202"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.TrackCompositeEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert length(request.segment_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id, room_name: ^room_name}} =
               EgressService.start_track_composite_egress(client, room_name, output)
    end

    test "starts track composite egress with track IDs", %{bypass: bypass, client: client} do
      room_name = "test_room"

      output = %ImageOutput{
        capture_interval: 5,
        width: 1920,
        height: 1080,
        filename_prefix: "screenshot"
      }

      opts = [audio_track_id: "audio1", video_track_id: "video1"]
      egress_id = "egress_303"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.TrackCompositeEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.audio_track_id == opts[:audio_track_id]
        assert request.video_track_id == opts[:video_track_id]
        assert length(request.image_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_track_composite_egress(client, room_name, output, opts)
    end
  end

  describe "start_track_egress/4" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StartTrackEgress"
    test "starts track egress with DirectFileOutput", %{bypass: bypass, client: client} do
      room_name = "test_room"
      track_id = "track_123"
      output = %DirectFileOutput{filepath: "track.mp4"}
      egress_id = "egress_404"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.TrackEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.track_id == track_id
        # Note: oneof fields are tested in set_output tests, just verify basic fields here

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id, room_name: ^room_name}} =
               EgressService.start_track_egress(client, room_name, track_id, output)
    end

    test "starts track egress with WebSocket URL", %{bypass: bypass, client: client} do
      room_name = "test_room"
      track_id = "track_456"
      websocket_url = "ws://example.com/egress"
      egress_id = "egress_505"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.TrackEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == room_name
        assert request.track_id == track_id
        # Note: oneof fields are tested in set_output tests, just verify basic fields here

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            room_name: room_name,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_track_egress(client, room_name, track_id, websocket_url)
    end
  end

  describe "start_web_egress/4" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StartWebEgress"
    test "starts web egress", %{bypass: bypass, client: client} do
      url = "https://example.com"
      output = %EncodedFileOutput{filepath: "web.mp4", file_type: :MP4}
      egress_id = "egress_606"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.WebEgressRequest.decode() |> Map.from_struct()

        assert request.url == url
        assert request.audio_only == false
        assert request.video_only == false
        assert request.await_start_signal == false
        assert length(request.file_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_web_egress(client, url, output)
    end

    test "starts web egress with options", %{bypass: bypass, client: client} do
      url = "https://example.com"
      output = %StreamOutput{protocol: :RTMP, urls: ["rtmp://example.com/live"]}
      opts = [audio_only: true, video_only: false, await_start_signal: true]
      egress_id = "egress_707"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.WebEgressRequest.decode() |> Map.from_struct()

        assert request.url == url
        assert request.audio_only == opts[:audio_only]
        assert request.video_only == opts[:video_only]
        assert request.await_start_signal == opts[:await_start_signal]
        assert length(request.stream_outputs) == 1

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.start_web_egress(client, url, output, opts)
    end
  end

  describe "update_layout/3" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/UpdateLayout"
    test "updates layout", %{bypass: bypass, client: client} do
      egress_id = "egress_808"
      layout = "grid"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateLayoutRequest.decode() |> Map.from_struct()

        assert request.egress_id == egress_id
        assert request.layout == layout

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.update_layout(client, egress_id, layout)
    end
  end

  describe "update_stream/3" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/UpdateStream"
    test "updates stream", %{bypass: bypass, client: client} do
      egress_id = "egress_909"

      opts = [
        add_output_urls: ["rtmp://example.com/new"],
        remove_output_urls: ["rtmp://example.com/old"]
      ]

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateStreamRequest.decode() |> Map.from_struct()

        assert request.egress_id == egress_id
        assert request.add_output_urls == opts[:add_output_urls]
        assert request.remove_output_urls == opts[:remove_output_urls]

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.update_stream(client, egress_id, opts)
    end

    test "updates stream with empty options", %{bypass: bypass, client: client} do
      egress_id = "egress_1010"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.UpdateStreamRequest.decode() |> Map.from_struct()

        assert request.egress_id == egress_id
        assert request.add_output_urls == []
        assert request.remove_output_urls == []

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_ACTIVE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id}} =
               EgressService.update_stream(client, egress_id)
    end
  end

  describe "list_egress/2" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/ListEgress"
    test "lists all egress", %{bypass: bypass, client: client} do
      egress1 = %Livekit.EgressInfo{
        egress_id: "egress_1",
        room_name: "room1",
        status: :EGRESS_ACTIVE
      }

      egress2 = %Livekit.EgressInfo{
        egress_id: "egress_2",
        room_name: "room2",
        status: :EGRESS_COMPLETE
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == ""
        assert request.egress_id == ""
        assert request.active == false

        response =
          %Livekit.ListEgressResponse{items: [egress1, egress2]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, items} = EgressService.list_egress(client)

      assert length(items) == 2
      assert Enum.any?(items, fn item -> item.egress_id == "egress_1" end)
      assert Enum.any?(items, fn item -> item.egress_id == "egress_2" end)
    end

    test "lists egress filtered by room_name", %{bypass: bypass, client: client} do
      egress = %Livekit.EgressInfo{
        egress_id: "egress_1",
        room_name: "test_room",
        status: :EGRESS_ACTIVE
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListEgressRequest.decode() |> Map.from_struct()

        assert request.room_name == "test_room"
        assert request.egress_id == ""
        assert request.active == false

        response =
          %Livekit.ListEgressResponse{items: [egress]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, [%Livekit.EgressInfo{room_name: "test_room"}]} =
               EgressService.list_egress(client, room_name: "test_room")
    end

    test "lists egress filtered by egress_id", %{bypass: bypass, client: client} do
      egress = %Livekit.EgressInfo{
        egress_id: "egress_123",
        room_name: "test_room",
        status: :EGRESS_ACTIVE
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListEgressRequest.decode() |> Map.from_struct()

        assert request.egress_id == "egress_123"
        assert request.room_name == ""
        assert request.active == false

        response =
          %Livekit.ListEgressResponse{items: [egress]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, [%Livekit.EgressInfo{egress_id: "egress_123"}]} =
               EgressService.list_egress(client, egress_id: "egress_123")
    end

    test "lists egress filtered by active", %{bypass: bypass, client: client} do
      egress = %Livekit.EgressInfo{
        egress_id: "egress_1",
        room_name: "test_room",
        status: :EGRESS_ACTIVE
      }

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.ListEgressRequest.decode() |> Map.from_struct()

        assert request.active == true

        response =
          %Livekit.ListEgressResponse{items: [egress]}
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, [%Livekit.EgressInfo{}]} = EgressService.list_egress(client, active: true)
    end
  end

  describe "stop_egress/2" do
    setup do
      bypass_client()
    end

    @url "/twirp/livekit.EgressService/StopEgress"
    test "stops egress", %{bypass: bypass, client: client} do
      egress_id = "egress_1111"

      Bypass.expect_once(bypass, "POST", @url, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request = body |> Livekit.StopEgressRequest.decode() |> Map.from_struct()

        assert request.egress_id == egress_id

        response =
          %Livekit.EgressInfo{
            egress_id: egress_id,
            status: :EGRESS_COMPLETE
          }
          |> Protobuf.encode()

        conn
        |> Plug.Conn.put_resp_content_type("application/protobuf")
        |> Plug.Conn.resp(200, response)
      end)

      assert {:ok, %Livekit.EgressInfo{egress_id: ^egress_id, status: :EGRESS_COMPLETE}} =
               EgressService.stop_egress(client, egress_id)
    end
  end

  describe "set_encoding_options/2" do
    setup do
      %{request: base_request()}
    end

    test "returns request unchanged when opts do not include :options", %{request: request} do
      result = EgressService.set_encoding_options(request, [])

      assert result == request
      # The :options field exists in the struct but should be nil when not set
      assert result.options == nil
      assert Protobuf.encode(result)
    end

    test "returns request unchanged when :options is nil", %{request: request} do
      result = EgressService.set_encoding_options(request, options: nil)

      assert result == request
      assert Protobuf.encode(result)
    end

    test "sets advanced type options when EncodingOptions struct is provided", %{request: request} do
      advanced_options = %EncodingOptions{
        width: 1920,
        height: 1080,
        framerate: 30,
        video_bitrate: 3000,
        audio_bitrate: 128
      }

      result = EgressService.set_encoding_options(request, options: advanced_options)

      assert result.options == {:advanced, advanced_options}
      assert result.room_name == "test_room"
      assert Protobuf.encode(result)
    end

    test "sets preset type options when EncodingOptionsPreset struct is provided", %{
      request: request
    } do
      preset = :H264_720P_30

      result = EgressService.set_encoding_options(request, options: preset)

      assert result.options == {:preset, preset}
      assert result.room_name == "test_room"
      assert Protobuf.encode(result)
    end

    test "preserves other request fields when setting options" do
      request = %RoomCompositeEgressRequest{
        room_name: "test_room",
        audio_only: true,
        video_only: false,
        layout: "grid",
        custom_base_url: "https://example.com"
      }

      advanced_options = %EncodingOptions{
        width: 1280,
        height: 720
      }

      result = EgressService.set_encoding_options(request, options: advanced_options)

      assert result.room_name == request.room_name
      assert result.audio_only == request.audio_only
      assert result.video_only == request.video_only
      assert result.layout == request.layout
      assert result.custom_base_url == request.custom_base_url
      assert result.options == {:advanced, advanced_options}
      assert Protobuf.encode(result)
    end
  end

  describe "set_output/2" do
    setup do
      %{request: base_request()}
    end

    defp encoded_file_output do
      %EncodedFileOutput{
        filepath: "test.mp4",
        file_type: :MP4
      }
    end

    defp segmented_file_output do
      %SegmentedFileOutput{
        filename_prefix: "test",
        playlist_name: "playlist.m3u8",
        protocol: :HLS_PROTOCOL
      }
    end

    defp stream_output do
      %StreamOutput{
        protocol: :RTMP,
        urls: ["rtmp://example.com/live"]
      }
    end

    defp image_output do
      %ImageOutput{
        capture_interval: 5,
        width: 1920,
        height: 1080,
        filename_prefix: "screenshot"
      }
    end

    # Single output tests (happy paths)
    test "sets single EncodedFileOutput", %{request: request} do
      output = encoded_file_output()

      result = EgressService.set_output(request, output)

      assert result.file_outputs == [output]
      assert result.segment_outputs == []
      assert result.stream_outputs == []
      assert result.image_outputs == []
      assert Protobuf.encode(result)
    end

    test "sets single SegmentedFileOutput", %{request: request} do
      output = segmented_file_output()

      result = EgressService.set_output(request, output)

      assert result.segment_outputs == [output]
      assert result.file_outputs == []
      assert result.stream_outputs == []
      assert result.image_outputs == []
      assert Protobuf.encode(result)
    end

    test "sets single StreamOutput", %{request: request} do
      output = stream_output()

      result = EgressService.set_output(request, output)

      assert result.stream_outputs == [output]
      assert result.file_outputs == []
      assert result.segment_outputs == []
      assert result.image_outputs == []
      assert Protobuf.encode(result)
    end

    test "sets single ImageOutput", %{request: request} do
      output = image_output()

      result = EgressService.set_output(request, output)

      assert result.image_outputs == [output]
      assert result.file_outputs == []
      assert result.segment_outputs == []
      assert result.stream_outputs == []
      assert Protobuf.encode(result)
    end

    # List output tests (happy paths)
    test "sets list with all output types", %{request: request} do
      outputs = [
        encoded_file_output(),
        segmented_file_output(),
        stream_output(),
        image_output()
      ]

      result = EgressService.set_output(request, outputs)

      assert length(result.file_outputs) == 1
      assert length(result.segment_outputs) == 1
      assert length(result.stream_outputs) == 1
      assert length(result.image_outputs) == 1
      assert Protobuf.encode(result)
    end

    test "sets list with file and stream outputs", %{request: request} do
      outputs = [encoded_file_output(), stream_output()]

      result = EgressService.set_output(request, outputs)

      assert length(result.file_outputs) == 1
      assert length(result.stream_outputs) == 1
      assert result.segment_outputs == []
      assert result.image_outputs == []
      assert Protobuf.encode(result)
    end

    test "sets list with segment and image outputs", %{request: request} do
      outputs = [segmented_file_output(), image_output()]

      result = EgressService.set_output(request, outputs)

      assert length(result.segment_outputs) == 1
      assert length(result.image_outputs) == 1
      assert result.file_outputs == []
      assert result.stream_outputs == []
      assert Protobuf.encode(result)
    end

    test "preserves other request fields when setting outputs" do
      request = %RoomCompositeEgressRequest{
        room_name: "test_room",
        audio_only: true,
        video_only: false,
        layout: "grid",
        custom_base_url: "https://example.com"
      }

      output = encoded_file_output()

      result = EgressService.set_output(request, output)

      assert result.room_name == "test_room"
      assert result.audio_only == true
      assert result.video_only == false
      assert result.layout == "grid"
      assert result.custom_base_url == "https://example.com"
      assert length(result.file_outputs) == 1
      assert Protobuf.encode(result)
    end

    # Error cases
    test "raises ArgumentError when output is nil", %{request: request} do
      assert_raise ArgumentError, ~r/output cannot be nil/, fn ->
        EgressService.set_output(request, nil)
      end
    end

    test "raises ArgumentError when output type is invalid", %{request: request} do
      assert_raise ArgumentError,
                   ~r/output must be one of: EncodedFileOutput, SegmentedFileOutput, StreamOutput, or ImageOutput/,
                   fn ->
                     EgressService.set_output(request, %{invalid: "output"})
                   end
    end

    test "raises ArgumentError when list contains invalid output type", %{request: request} do
      outputs = [encoded_file_output(), %{invalid: "output"}]

      assert_raise ArgumentError,
                   ~r/output must be one of: EncodedFileOutput, SegmentedFileOutput, StreamOutput, or ImageOutput/,
                   fn ->
                     EgressService.set_output(request, outputs)
                   end
    end

    test "raises ArgumentError when list contains multiple file outputs", %{request: request} do
      outputs = [encoded_file_output(), encoded_file_output()]

      assert_raise ArgumentError, ~r/cannot add multiple file outputs/, fn ->
        EgressService.set_output(request, outputs)
      end
    end

    test "raises ArgumentError when list contains multiple segment outputs", %{request: request} do
      outputs = [segmented_file_output(), segmented_file_output()]

      assert_raise ArgumentError, ~r/cannot add multiple segmented file outputs/, fn ->
        EgressService.set_output(request, outputs)
      end
    end

    test "raises ArgumentError when list contains multiple stream outputs", %{request: request} do
      outputs = [stream_output(), stream_output()]

      assert_raise ArgumentError, ~r/cannot add multiple stream outputs/, fn ->
        EgressService.set_output(request, outputs)
      end
    end

    test "raises ArgumentError when list contains multiple image outputs", %{request: request} do
      outputs = [image_output(), image_output()]

      assert_raise ArgumentError, ~r/cannot add multiple image outputs/, fn ->
        EgressService.set_output(request, outputs)
      end
    end

    test "raises ArgumentError when setting file output twice on same request", %{
      request: request
    } do
      output = encoded_file_output()

      # First set should succeed
      result1 = EgressService.set_output(request, output)
      assert length(result1.file_outputs) == 1

      # Second set should fail
      assert_raise ArgumentError, ~r/cannot add multiple file outputs/, fn ->
        EgressService.set_output(result1, output)
      end
    end

    test "raises ArgumentError when setting segment output twice on same request", %{
      request: request
    } do
      output = segmented_file_output()

      # First set should succeed
      result1 = EgressService.set_output(request, output)
      assert length(result1.segment_outputs) == 1

      # Second set should fail
      assert_raise ArgumentError, ~r/cannot add multiple segmented file outputs/, fn ->
        EgressService.set_output(result1, output)
      end
    end

    test "raises ArgumentError when setting stream output twice on same request", %{
      request: request
    } do
      output = stream_output()

      # First set should succeed
      result1 = EgressService.set_output(request, output)
      assert length(result1.stream_outputs) == 1

      # Second set should fail
      assert_raise ArgumentError, ~r/cannot add multiple stream outputs/, fn ->
        EgressService.set_output(result1, output)
      end
    end

    test "raises ArgumentError when setting image output twice on same request", %{
      request: request
    } do
      output = image_output()

      # First set should succeed
      result1 = EgressService.set_output(request, output)
      assert length(result1.image_outputs) == 1

      # Second set should fail
      assert_raise ArgumentError, ~r/cannot add multiple image outputs/, fn ->
        EgressService.set_output(result1, output)
      end
    end

    test "works with ParticipantEgressRequest" do
      request = %ParticipantEgressRequest{
        room_name: "test_room",
        identity: "participant1"
      }

      output = encoded_file_output()

      result = EgressService.set_output(request, output)

      assert length(result.file_outputs) == 1
      assert Protobuf.encode(result)
    end

    test "works with TrackCompositeEgressRequest" do
      request = %TrackCompositeEgressRequest{
        room_name: "test_room",
        audio_track_id: "audio1"
      }

      output = stream_output()

      result = EgressService.set_output(request, output)

      assert length(result.stream_outputs) == 1
      assert Protobuf.encode(result)
    end

    test "works with WebEgressRequest" do
      request = %WebEgressRequest{
        url: "https://example.com",
        audio_only: false
      }

      output = image_output()

      result = EgressService.set_output(request, output)

      assert length(result.image_outputs) == 1
      assert Protobuf.encode(result)
    end
  end
end

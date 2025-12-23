defmodule ExLivekit.EgressService do
  alias ExLivekit.Client
  alias ExLivekit.Client.Error
  alias ExLivekit.Grants.VideoGrant

  alias Livekit.{
    EgressInfo,
    ListEgressRequest,
    ListEgressResponse,
    ParticipantEgressRequest,
    RoomCompositeEgressRequest,
    StopEgressRequest,
    TrackCompositeEgressRequest,
    TrackEgressRequest,
    UpdateLayoutRequest,
    UpdateStreamRequest,
    WebEgressRequest
  }

  @preset_types [
    :H264_720P_30,
    :H264_720P_60,
    :H264_1080P_30,
    :H264_1080P_60,
    :PORTRAIT_H264_720P_30,
    :PORTRAIT_H264_720P_60,
    :PORTRAIT_H264_1080P_30,
    :PORTRAIT_H264_1080P_60
  ]

  @svc "EgressService"

  @type opts :: Keyword.t()
  @type room_name :: String.t()
  @type egress_id :: String.t()
  @type output ::
          Livekit.EncodedFileOutput.t()
          | Livekit.SegmentedFileOutput.t()
          | Livekit.StreamOutput.t()
          | Livekit.ImageOutput.t()
          | [
              Livekit.EncodedFileOutput.t()
              | Livekit.SegmentedFileOutput.t()
              | Livekit.StreamOutput.t()
              | Livekit.ImageOutput.t()
            ]

  @spec start_room_composite_egress(Client.t(), room_name(), output(), opts()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_room_composite_egress(%Client{} = client, room_name, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    base_request = %RoomCompositeEgressRequest{
      room_name: room_name,
      layout: opts[:layout],
      audio_only: opts[:audio_only] || false,
      video_only: opts[:video_only] || false,
      custom_base_url: opts[:custom_base_url],
      webhooks: opts[:webhooks] || []
    }

    request =
      base_request
      |> set_encoding_options(opts)
      |> set_output(output)

    case Client.request(client, @svc, "StartRoomCompositeEgress", request, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec start_participant_egress(Client.t(), room_name(), String.t(), output(), opts()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_participant_egress(%Client{} = client, room_name, identity, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    request = %ParticipantEgressRequest{
      room_name: room_name,
      identity: identity,
      screen_share: opts[:screen_share] || false,
      webhooks: opts[:webhooks] || []
    }

    payload =
      request
      |> set_encoding_options(opts)
      |> set_output(output)

    case Client.request(client, @svc, "StartParticipantEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec start_track_composite_egress(Client.t(), room_name(), output(), opts()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_track_composite_egress(%Client{} = client, room_name, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    request = %TrackCompositeEgressRequest{
      room_name: room_name,
      audio_track_id: opts[:audio_track_id],
      video_track_id: opts[:video_track_id],
      webhooks: opts[:webhooks] || []
    }

    payload =
      request
      |> set_encoding_options(opts)
      |> set_output(output)

    case Client.request(client, @svc, "StartTrackCompositeEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec start_track_egress(
          Client.t(),
          room_name(),
          String.t(),
          Livekit.DirectFileOutput.t() | String.t()
        ) :: {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_track_egress(%Client{} = client, room_name, track_id, output) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    request = %TrackEgressRequest{
      room_name: room_name,
      track_id: track_id
    }

    payload =
      cond do
        is_struct(output, Livekit.DirectFileOutput) ->
          Map.put(request, :file, output)

        is_binary(output) ->
          Map.put(request, :websocket_url, output)

        true ->
          raise ArgumentError,
                "output must be a DirectFileOutput struct or a WebSocket URL string, got: #{inspect(output)}"
      end

    case Client.request(client, @svc, "StartTrackEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec start_web_egress(Client.t(), String.t(), output(), opts()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_web_egress(%Client{} = client, url, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    request = %WebEgressRequest{
      url: url,
      audio_only: opts[:audio_only] || false,
      video_only: opts[:video_only] || false,
      await_start_signal: opts[:await_start_signal] || false,
      webhooks: opts[:webhooks] || []
    }

    payload =
      request
      |> set_encoding_options(opts)
      |> set_output(output)

    case Client.request(client, @svc, "StartWebEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec update_layout(Client.t(), egress_id(), String.t()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def update_layout(%Client{} = client, egress_id, layout) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    payload = %UpdateLayoutRequest{
      egress_id: egress_id,
      layout: layout
    }

    case Client.request(client, @svc, "UpdateLayout", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec update_stream(Client.t(), egress_id(), opts()) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def update_stream(%Client{} = client, egress_id, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    payload = %UpdateStreamRequest{
      egress_id: egress_id,
      add_output_urls: opts[:add_output_urls] || [],
      remove_output_urls: opts[:remove_output_urls] || []
    }

    case Client.request(client, @svc, "UpdateStream", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec list_egress(Client.t(), opts()) ::
          {:ok, ListEgressResponse.t()} | {:error, Error.t()}
  def list_egress(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    payload = %ListEgressRequest{
      room_name: opts[:room_name],
      egress_id: opts[:egress_id],
      active: opts[:active] || false
    }

    case Client.request(client, @svc, "ListEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, ListEgressResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec stop_egress(Client.t(), egress_id()) :: {:ok, EgressInfo.t()} | {:error, Error.t()}
  def stop_egress(%Client{} = client, egress_id) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    payload = %StopEgressRequest{egress_id: egress_id}

    case Client.request(client, @svc, "StopEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  # Helper function to set encoding options (preset or advanced, but not both)
  @doc false
  def set_encoding_options(request, opts) do
    case opts[:options] do
      %Livekit.EncodingOptions{} = advanced ->
        Map.put(request, :options, {:advanced, advanced})

      preset when preset in @preset_types ->
        Map.put(request, :options, {:preset, preset})

      _ ->
        request
    end
  end

  # Helper function to set output fields on request structs
  # Supports single output or array of outputs (up to one of each type)
  @spec set_output(
          RoomCompositeEgressRequest.t()
          | ParticipantEgressRequest.t()
          | TrackCompositeEgressRequest.t()
          | WebEgressRequest.t(),
          output()
        ) ::
          RoomCompositeEgressRequest.t()
          | ParticipantEgressRequest.t()
          | TrackCompositeEgressRequest.t()
          | WebEgressRequest.t()
  def set_output(_request, nil) do
    raise ArgumentError, "output cannot be nil"
  end

  def set_output(request, outputs) when is_list(outputs) do
    # Track which output types we've seen to prevent duplicates
    seen_types = %{
      file: false,
      segment: false,
      stream: false,
      image: false
    }

    Enum.reduce(outputs, {request, seen_types}, fn output, {acc, seen} ->
      process_list_output(acc, output, seen)
    end)
    |> elem(0)
  end

  def set_output(request, output) do
    set_single_output(request, output)
  end

  defp process_list_output(request, %Livekit.EncodedFileOutput{} = output, seen) do
    if seen.file do
      raise ArgumentError, "cannot add multiple file outputs"
    end

    {set_single_output(request, output), %{seen | file: true}}
  end

  defp process_list_output(request, %Livekit.SegmentedFileOutput{} = output, seen) do
    if seen.segment do
      raise ArgumentError, "cannot add multiple segmented file outputs"
    end

    {set_single_output(request, output), %{seen | segment: true}}
  end

  defp process_list_output(request, %Livekit.StreamOutput{} = output, seen) do
    if seen.stream do
      raise ArgumentError, "cannot add multiple stream outputs"
    end

    {set_single_output(request, output), %{seen | stream: true}}
  end

  defp process_list_output(request, %Livekit.ImageOutput{} = output, seen) do
    if seen.image do
      raise ArgumentError, "cannot add multiple image outputs"
    end

    {set_single_output(request, output), %{seen | image: true}}
  end

  defp process_list_output(_request, output, _seen) do
    raise ArgumentError,
          "output must be one of: EncodedFileOutput, SegmentedFileOutput, StreamOutput, or ImageOutput, got: #{inspect(output)}"
  end

  defp set_single_output(request, %Livekit.EncodedFileOutput{} = output) do
    existing = request.file_outputs || []

    unless Enum.empty?(existing) do
      raise ArgumentError, "cannot add multiple file outputs"
    end

    %{request | file_outputs: [output]}
  end

  defp set_single_output(request, %Livekit.SegmentedFileOutput{} = output) do
    existing = request.segment_outputs || []

    unless Enum.empty?(existing) do
      raise ArgumentError, "cannot add multiple segmented file outputs"
    end

    %{request | segment_outputs: [output]}
  end

  defp set_single_output(request, %Livekit.StreamOutput{} = output) do
    existing = request.stream_outputs || []

    unless Enum.empty?(existing) do
      raise ArgumentError, "cannot add multiple stream outputs"
    end

    %{request | stream_outputs: [output]}
  end

  defp set_single_output(request, %Livekit.ImageOutput{} = output) do
    existing = request.image_outputs || []

    unless Enum.empty?(existing) do
      raise ArgumentError, "cannot add multiple image outputs"
    end

    %{request | image_outputs: [output]}
  end

  defp set_single_output(_request, output) do
    raise ArgumentError,
          "output must be one of: EncodedFileOutput, SegmentedFileOutput, StreamOutput, or ImageOutput, got: #{inspect(output)}"
  end
end

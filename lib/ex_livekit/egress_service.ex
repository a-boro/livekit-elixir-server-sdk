defmodule ExLivekit.EgressService do
  @moduledoc """
  Module for interacting with the LiveKit Egress Service.

  This module provides functionality to start, stop, and update egresses.
  """

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

  @type audio_mixing :: :DEFAULT_MIXING | :NO_MIXING | :REPLACE_SOURCE
  @type encoding_options_preset ::
          :H264_720P_30
          | :H264_720P_60
          | :H264_1080P_30
          | :H264_1080P_60
          | :PORTRAIT_H264_720P_30
          | :PORTRAIT_H264_720P_60
          | :PORTRAIT_H264_1080P_30
          | :PORTRAIT_H264_1080P_60

  @type create_egress_request ::
          RoomCompositeEgressRequest.t()
          | ParticipantEgressRequest.t()
          | TrackCompositeEgressRequest.t()
          | WebEgressRequest.t()

  @type start_room_composite_egress_opts :: [
          layout: String.t(),
          audio_only: boolean(),
          video_only: boolean(),
          audio_mixing: audio_mixing(),
          custom_base_url: String.t(),
          webhooks: [Livekit.WebhookConfig.t()],
          options: Livekit.EncodingOptions.t() | encoding_options_preset()
        ]

  @doc """
  Starts a room composite egress.

  Output can be a single output or a list of outputs.
  If a list of outputs is provided, only one of each type of output can be provided.

  Options:
  - layout: the layout to use for the egress [optional], default is "grid"
  - audio_only: whether to only record audio [optional], default is false
  - video_only: whether to only record video [optional], default is false
  - audio_mixing: the audio mixing to use for the egress [optional], default is :DEFAULT_MIXING
  - custom_base_url: the custom base URL to use for the egress [optional]
  - webhooks: the webhooks to call for the egress [optional], default is []
  - options: the encoding options or preset to use for the egress [optional]
  """
  @spec start_room_composite_egress(
          Client.t(),
          room_name(),
          output(),
          start_room_composite_egress_opts()
        ) ::
          {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_room_composite_egress(%Client{} = client, room_name, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    base_request = %RoomCompositeEgressRequest{
      room_name: room_name,
      layout: opts[:layout],
      audio_only: opts[:audio_only] || false,
      video_only: opts[:video_only] || false,
      audio_mixing: opts[:audio_mixing] || :DEFAULT_MIXING,
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

  @type start_participant_egress_opts :: [
          screen_share: boolean(),
          webhooks: [Livekit.WebhookConfig.t()],
          options: Livekit.EncodingOptions.t() | encoding_options_preset()
        ]

  @doc """
  Starts a participant egress.

  Output can be a single output or a list of outputs.
  If a list of outputs is provided, only one of each type of output can be provided.

  Options:
  - screen_share: whether to record the screen share [optional], default is false
  - webhooks: extra the webhooks to call for the egress [optional], default is []
  - options: the encoding options or preset to use for the egress [optional]
  """

  @spec start_participant_egress(
          Client.t(),
          room_name(),
          String.t(),
          output(),
          start_participant_egress_opts()
        ) ::
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
      {:ok, body} -> {:ok, EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @type start_track_composite_egress_opts :: [
          audio_track_id: String.t(),
          video_track_id: String.t(),
          webhooks: [Livekit.WebhookConfig.t()],
          options: Livekit.EncodingOptions.t() | encoding_options_preset()
        ]

  @doc """
  Starts a track composite egress.

  Output can be a single output or a list of outputs.
  If a list of outputs is provided, only one of each type of output can be provided.

  Options:
  - audio_track_id: the id of the audio track to record [optional]
  - video_track_id: the id of the video track to record [optional]
  - webhooks: extra the webhooks to call for the egress [optional], default is []
  - options: the encoding options or preset to use for the egress [optional]
  """
  @spec start_track_composite_egress(
          Client.t(),
          room_name(),
          output(),
          start_track_composite_egress_opts()
        ) ::
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

  @type start_track_egress_opts :: [webhooks: [Livekit.WebhookConfig.t()]]
  @type websocket_url :: String.t()

  @doc """
  Record tracks individually, without transcoding.

  Output: can be either a Livekit.DirectFileOutput struct or a WebSocket URL string.

  Options:
  - webhooks: extra the webhooks to call for the egress [optional], default is []
  """
  @spec start_track_egress(
          Client.t(),
          room_name(),
          String.t(),
          Livekit.DirectFileOutput.t() | websocket_url(),
          start_track_egress_opts()
        ) :: {:ok, EgressInfo.t()} | {:error, Error.t()}
  def start_track_egress(%Client{} = client, room_name, track_id, output, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    request = %TrackEgressRequest{
      room_name: room_name,
      track_id: track_id,
      webhooks: opts[:webhooks] || []
    }

    payload =
      case output do
        %Livekit.DirectFileOutput{} = output ->
          Map.put(request, :output, {:file, output})

        websocket_url when is_binary(websocket_url) ->
          Map.put(request, :output, {:websocket_url, websocket_url})

        _ ->
          raise ArgumentError,
                "output must be a DirectFileOutput struct or a WebSocket URL string, got: #{inspect(output)}"
      end

    case Client.request(client, @svc, "StartTrackEgress", payload, auth_headers) do
      {:ok, body} -> {:ok, EgressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @type start_web_egress_opts :: [
          audio_only: boolean(),
          video_only: boolean(),
          await_start_signal: boolean(),
          webhooks: [Livekit.WebhookConfig.t()],
          options: Livekit.EncodingOptions.t() | encoding_options_preset()
        ]

  @doc """
  Starts a web egress to record any website.

  Output can be a single output or a list of outputs.
  If a list of outputs is provided, only one of each type of output can be provided.

  Options:
  - audio_only: whether to only record audio [optional], default is false
  - video_only: whether to only record video [optional], default is false
  - await_start_signal: whether to await a start signal before recording [optional], default is false
  - webhooks: extra the webhooks to call for the egress [optional], default is []
  - options: the encoding options or preset to use for the egress [optional]
  """
  @spec start_web_egress(Client.t(), String.t(), output(), start_web_egress_opts()) ::
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

  @doc """
  Updates the layout for an existing egress.
  """
  @spec update_layout(Client.t(), egress_id(), layout: String.t()) ::
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

  @type update_stream_opts :: [
          add_output_urls: [String.t()],
          remove_output_urls: [String.t()]
        ]
  @doc """
  Updates a stream endpoint for an existing egress.

  Options:
  - add_output_urls: the URLs to add to the stream [optional], default is []
  - remove_output_urls: the URLs to remove from the stream [optional], default is []

  ## Examples

  ```elixir
  {:ok, egress} = ExLivekit.EgressService.update_stream(client, "egress_id", add_output_urls: ["https://example.com/stream.mp4"])
  {:ok, egress} = ExLivekit.EgressService.update_stream(client, "egress_id", remove_output_urls: ["https://example.com/stream.mp4"])
  {:ok, egress} = ExLivekit.EgressService.update_stream(client, "egress_id", add_output_urls: ["https://example.com/stream.mp4"], remove_output_urls: ["https://example.com/stream.mp4"])
  ```
  """
  @spec update_stream(Client.t(), egress_id(), update_stream_opts()) ::
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

  @type list_egress_opts :: [
          room_name: room_name(),
          egress_id: egress_id(),
          active: boolean()
        ]
  @doc """
  Lists egresses that are active on the server.
  Options:
  - room_name: the room name to list egresses for [optional]
  - egress_id: the id of the egress to list [optional]
  - active: whether to list active egresses only [optional], default is false

  ## Examples

  ```elixir
  {:ok, egresses} = ExLivekit.EgressService.list_egress(client)
  {:ok, egresses} = ExLivekit.EgressService.list_egress(client, room_name: "room_name")
  {:ok, egresses} = ExLivekit.EgressService.list_egress(client, egress_id: "egress_id")
  {:ok, egresses} = ExLivekit.EgressService.list_egress(client, active: true)
  {:ok, egresses} = ExLivekit.EgressService.list_egress(client, room_name: "room_name", active: true)
  ```
  """
  @spec list_egress(Client.t(), list_egress_opts()) ::
          {:ok, [EgressInfo.t()]} | {:error, Error.t()}
  def list_egress(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{room_record: true})

    payload = %ListEgressRequest{
      room_name: opts[:room_name],
      egress_id: opts[:egress_id],
      active: opts[:active] || false
    }

    case Client.request(client, @svc, "ListEgress", payload, auth_headers) do
      {:ok, body} ->
        resp = ListEgressResponse.decode(body)
        {:ok, resp.items}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Stops an existing egress.

  ## Examples

  ```elixir
  {:ok, egress} = ExLivekit.EgressService.stop_egress(client, "egress_id")
  ```
  """
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
  @doc false
  @spec set_output(create_egress_request(), output()) :: create_egress_request()
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

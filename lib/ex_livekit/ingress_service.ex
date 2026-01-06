defmodule ExLivekit.IngressService do
  @moduledoc """
  Module for interacting with the LiveKit Ingress Service.

  This module provides functionality to create, list, delete, and update ingresses.
  """

  alias ExLivekit.Client
  alias ExLivekit.Client.Error
  alias ExLivekit.Grants.VideoGrant

  alias Livekit.{
    CreateIngressRequest,
    DeleteIngressRequest,
    IngressInfo,
    ListIngressRequest,
    UpdateIngressRequest
  }

  @svc "Ingress"

  @type opts :: Keyword.t()
  @type ingress_id :: String.t()

  @type create_ingress_opts :: [
          input_type: :RTMP_INPUT | :WHIP_INPUT | :URL_INPUT,
          url: String.t(),
          name: String.t(),
          room_name: String.t(),
          participant_identity: String.t(),
          participant_name: String.t(),
          enable_transcoding: boolean(),
          audio: Livekit.IngressAudioOptions.t(),
          video: Livekit.IngressVideoOptions.t()
        ]
  @doc """
  Creates a new ingress.

  Input Options:
  - input_type: :RTMP_INPUT, :WHIP_INPUT, :URL_INPUT [required]
  - url: HTTP(S) or SRT url to the file or stream [only for :URL_INPUT]
  - name: name to identify the ingress [optional]
  - room_name: the room name to publish to [required]
  - participant_identity: Unique identity for the room participant the Ingress service will connect as [required]
  - participant_name: Name displayed in the room for the participant [optional]
  - enable_transcoding: whether to enable transcoding or forward the input media directly. Transcoding is required for all input types except WHIP. For WHIP, the default is to not transcode. [optional]
  - audio: audio options for the ingress [optional]
  - video: video options for the ingress [optional]


  @spec create_ingress(Client.t(), create_ingress_opts()) :: {:ok, IngressInfo.t()} | {:error, Error.t()}
  ## RTMP Example

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.create_ingress(
    client,
    input_type: :RTMP_INPUT,
    name: "example",
    room_name: "room_name",
    participant_identity: "participant_identity",
    participant_name: "participant_name",
    enable_transcoding: true
  )
  ```

  ## WHIP Example

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.create_ingress(
    client,
    input_type: :WHIP_INPUT,
    name: "example",
    room_name: "room_name",
    participant_identity: "participant_identity",
    participant_name: "participant_name",
    enable_transcoding: false
  )
  ```

  ## URL Example

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.create_ingress(
    client,
    input_type: :URL_INPUT,
    url: "https://example.com/stream.mp4",
    name: "example",
    room_name: "room_name",
    participant_identity: "participant_identity",
    participant_name: "participant_name",
    enable_transcoding: true
  )
  ```
  """
  @spec create_ingress(Client.t(), create_ingress_opts()) ::
          {:ok, IngressInfo.t()} | {:error, Error.t()}
  def create_ingress(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %CreateIngressRequest{
      input_type: opts[:input_type],
      url: opts[:url],
      name: opts[:name],
      room_name: opts[:room_name],
      participant_identity: opts[:participant_identity],
      participant_name: opts[:participant_name],
      enable_transcoding: opts[:enable_transcoding],
      audio: opts[:audio],
      video: opts[:video]
    }

    case Client.request(client, @svc, "CreateIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.IngressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @type update_ingress_opts :: [
          name: String.t(),
          room_name: String.t(),
          participant_identity: String.t(),
          participant_name: String.t(),
          enable_transcoding: boolean(),
          audio: Livekit.IngressAudioOptions.t(),
          video: Livekit.IngressVideoOptions.t()
        ]
  @doc """
  Updates an existing ingress.

  Options:
  - name: optional, name to identify the ingress
  - room_name: optional, the room name to publish to
  - participant_identity: optional, Unique identity for the room participant the Ingress service will connect as
  - participant_name: optional, Name displayed in the room for the participant
  - enable_transcoding: optional, whether to enable transcoding or forward the input media directly. Transcoding is required for all input types except WHIP. For WHIP, the default is to not transcode.
  - audio: optional, audio options for the ingress
  - video: optional, video options for the ingress

  ## Examples

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.update_ingress(client,
    "ingress_id",
    name: "example",
    room_name: "room_name",
    participant_identity: "participant_identity",
    participant_name: "participant_name",
    enable_transcoding: true
  )
  ```
  """
  @spec update_ingress(Client.t(), ingress_id(), update_ingress_opts()) ::
          {:ok, IngressInfo.t()} | {:error, Error.t()}
  def update_ingress(%Client{} = client, ingress_id, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %UpdateIngressRequest{
      ingress_id: ingress_id,
      name: opts[:name],
      room_name: opts[:room_name],
      participant_identity: opts[:participant_identity],
      participant_name: opts[:participant_name],
      enable_transcoding: opts[:enable_transcoding],
      audio: opts[:audio],
      video: opts[:video]
    }

    case Client.request(client, @svc, "UpdateIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.IngressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @type list_ingresses_opts :: [
          room_name: String.t(),
          ingress_id: ingress_id()
        ]
  @doc """
  Lists ingresses.

  Options:
  - room_name: the room name to list ingresses for
  - ingress_id: the id of the ingress to list

  ## Examples

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.list_ingresses(client, room_name: "room_name", ingress_id: "ingress_id")
  ```
  """
  @spec list_ingresses(Client.t(), list_ingresses_opts()) ::
          {:ok, [IngressInfo.t()]} | {:error, Error.t()}
  def list_ingresses(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %ListIngressRequest{room_name: opts[:room_name], ingress_id: opts[:ingress_id]}

    case Client.request(client, @svc, "ListIngress", payload, auth_headers) do
      {:ok, body} ->
        resp = Livekit.ListIngressResponse.decode(body)
        {:ok, resp.items}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Deletes an existing ingress.

  ## Examples

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.delete_ingress(client, ingress_id: "ingress_id")
  ```
  """
  @spec delete_ingress(Client.t(), ingress_id()) :: {:ok, IngressInfo.t()} | {:error, Error.t()}
  def delete_ingress(%Client{} = client, ingress_id) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %DeleteIngressRequest{ingress_id: ingress_id}

    case Client.request(client, @svc, "DeleteIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.IngressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end
end

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
    ListIngressResponse,
    UpdateIngressRequest
  }

  @svc "Ingress"

  @type opts :: Keyword.t()
  @type ingress_id :: String.t()

  @type create_ingress_opts :: [
          input_type: Livekit.IngressInput.t(),
          url: String.t(),
          name: String.t(),
          room_name: String.t(),
          participant_identity: String.t(),
          participant_name: String.t(),
          participant_metadata: String.t()
        ]
  @doc """
  Creates a new ingress.

  Options:
  - input_type: the type of input to use for the ingress
  - url: the url to use for the ingress
  - name: the name to use for the ingress
  @spec create_ingress(Client.t(), create_ingress_opts()) :: {:ok, IngressInfo.t()} | {:error, Error.t()}
  ## Examples

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.create_ingress(client, input_type: :URL_INPUT, url: "https://example.com/stream.mp4", name: "example", room_name: "room_name", participant_identity: "participant_identity", participant_name: "participant_name", participant_metadata: "participant_metadata")
  ```
  """
  def create_ingress(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %CreateIngressRequest{
      input_type: opts[:input_type],
      url: opts[:url],
      name: opts[:name],
      room_name: opts[:room_name],
      participant_identity: opts[:participant_identity],
      participant_name: opts[:participant_name],
      participant_metadata: opts[:participant_metadata]
    }

    case Client.request(client, @svc, "CreateIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.IngressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @type update_ingress_opts :: [
          ingress_id: ingress_id(),
          name: String.t(),
          room_name: String.t(),
          participant_identity: String.t(),
          participant_name: String.t(),
          participant_metadata: String.t()
        ]
  @doc """
  Updates an existing ingress.

  Options:
  - ingress_id: the id of the ingress to update
  - name: the name to update
  - room_name: the room name to update
  - participant_identity: the participant identity to update
  - participant_name: the participant name to update
  - participant_metadata: the participant metadata to update

  ## Examples

  ```elixir
  {:ok, ingress} = ExLivekit.IngressService.update_ingress(client,
    ingress_id: "ingress_id",
    name: "example",
    room_name: "room_name",
    participant_identity: "participant_identity",
    participant_name: "participant_name",
    participant_metadata: "participant_metadata"
  )
  ```
  """
  @spec update_ingress(Client.t(), update_ingress_opts()) ::
          {:ok, IngressInfo.t()} | {:error, Error.t()}
  def update_ingress(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %UpdateIngressRequest{
      ingress_id: opts[:ingress_id],
      name: opts[:name],
      room_name: opts[:room_name],
      participant_identity: opts[:participant_identity],
      participant_name: opts[:participant_name],
      participant_metadata: opts[:participant_metadata]
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
          {:ok, ListIngressResponse.t()} | {:error, Error.t()}
  def list_ingresses(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %ListIngressRequest{room_name: opts[:room_name], ingress_id: opts[:ingress_id]}

    case Client.request(client, @svc, "ListIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.ListIngressResponse.decode(body)}
      {:error, error} -> {:error, error}
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

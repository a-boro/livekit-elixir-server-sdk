defmodule ExLivekit.IngressService do
  alias ExLivekit.Client
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

  @spec create_ingress(Client.t(), opts()) :: {:ok, IngressInfo.t()} | {:error, term()}
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

  @spec update_ingress(Client.t(), opts()) :: {:ok, IngressInfo.t()} | {:error, term()}
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

  @spec list_ingresses(Client.t(), opts()) ::
          {:ok, ListIngressResponse.t()} | {:error, term()}
  def list_ingresses(%Client{} = client, opts \\ []) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %ListIngressRequest{room_name: opts[:room_name], ingress_id: opts[:ingress_id]}

    case Client.request(client, @svc, "ListIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.ListIngressResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec delete_ingress(Client.t(), ingress_id()) :: {:ok, IngressInfo.t()} | {:error, term()}
  def delete_ingress(%Client{} = client, ingress_id) do
    auth_headers = Client.auth_headers(client, video_grant: %VideoGrant{ingress_admin: true})

    payload = %DeleteIngressRequest{ingress_id: ingress_id}

    case Client.request(client, @svc, "DeleteIngress", payload, auth_headers) do
      {:ok, body} -> {:ok, Livekit.IngressInfo.decode(body)}
      {:error, error} -> {:error, error}
    end
  end
end

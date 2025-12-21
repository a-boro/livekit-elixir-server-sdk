defmodule ExLivekit.AgentDispatchService do
  alias ExLivekit.Client
  alias ExLivekit.Grants.VideoGrant

  alias Livekit.{
    AgentDispatch,
    CreateAgentDispatchRequest,
    DeleteAgentDispatchRequest,
    ListAgentDispatchRequest,
    ListAgentDispatchResponse
  }

  @svc "AgentDispatchService"

  @spec create_dispatch(Client.t(), String.t(), String.t(), String.t() | nil) ::
          {:ok, AgentDispatch.t()} | {:error, term()}
  def create_dispatch(%Client{} = client, room_name, agent_name, metadata \\ nil) do
    payload = %CreateAgentDispatchRequest{
      agent_name: agent_name,
      room: room_name,
      metadata: metadata
    }

    case Client.request(client, @svc, "CreateDispatch", payload, agent_headers(client, room_name)) do
      {:ok, body} -> {:ok, AgentDispatch.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec delete_dispatch(Client.t(), String.t(), String.t()) ::
          {:ok, AgentDispatch.t()} | {:error, term()}
  def delete_dispatch(%Client{} = client, dispatch_id, room_name) do
    payload = %DeleteAgentDispatchRequest{
      dispatch_id: dispatch_id,
      room: room_name
    }

    case Client.request(client, @svc, "DeleteDispatch", payload, agent_headers(client, room_name)) do
      {:ok, body} -> {:ok, AgentDispatch.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  @spec get_dispatch(Client.t(), String.t(), String.t()) ::
          {:ok, AgentDispatch.t()} | {:error, term()}
  def get_dispatch(%Client{} = client, dispatch_id, room_name) do
    payload = %ListAgentDispatchRequest{
      dispatch_id: dispatch_id,
      room: room_name
    }

    case Client.request(client, @svc, "GetDispatch", payload, agent_headers(client, room_name)) do
      {:ok, body} ->
        res = ListAgentDispatchResponse.decode(body)

        case res.agent_dispatches do
          [dispatch] -> {:ok, dispatch}
          [] -> {:ok, nil}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec list_dispatch(Client.t(), String.t()) ::
          {:ok, ListAgentDispatchResponse.t()} | {:error, term()}
  def list_dispatch(%Client{} = client, room_name) do
    payload = %ListAgentDispatchRequest{
      room: room_name
    }

    case Client.request(client, @svc, "ListDispatch", payload, agent_headers(client, room_name)) do
      {:ok, body} -> {:ok, ListAgentDispatchResponse.decode(body)}
      {:error, error} -> {:error, error}
    end
  end

  defp agent_headers(client, room_name) do
    Client.auth_headers(client, video_grant: %VideoGrant{room_admin: true, room: room_name})
  end
end

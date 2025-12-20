defmodule ExLivekit do
  use Application

  def start(_type, _args) do
    children = [
      http_client_child_spec()
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ExLivekit.Supervisor)
  end

  defp http_client_child_spec do
    http_client = ExLivekit.Config.http_client()
    http_client.child_spec()
  end
end

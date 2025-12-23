defmodule Livekit.CreateAgentDispatchRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :agent_name, 1, type: :string, json_name: "agentName"
  field :room, 2, type: :string
  field :metadata, 3, type: :string
end

defmodule Livekit.RoomAgentDispatch do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :agent_name, 1, type: :string, json_name: "agentName"
  field :metadata, 2, type: :string
end

defmodule Livekit.DeleteAgentDispatchRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :dispatch_id, 1, type: :string, json_name: "dispatchId"
  field :room, 2, type: :string
end

defmodule Livekit.ListAgentDispatchRequest do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :dispatch_id, 1, type: :string, json_name: "dispatchId"
  field :room, 2, type: :string
end

defmodule Livekit.ListAgentDispatchResponse do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :agent_dispatches, 1,
    repeated: true,
    type: Livekit.AgentDispatch,
    json_name: "agentDispatches"
end

defmodule Livekit.AgentDispatch do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :string
  field :agent_name, 2, type: :string, json_name: "agentName"
  field :room, 3, type: :string
  field :metadata, 4, type: :string
  field :state, 5, type: Livekit.AgentDispatchState
end

defmodule Livekit.AgentDispatchState do
  
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :jobs, 1, repeated: true, type: Livekit.Job
  field :created_at, 2, type: :int64, json_name: "createdAt"
  field :deleted_at, 3, type: :int64, json_name: "deletedAt"
end

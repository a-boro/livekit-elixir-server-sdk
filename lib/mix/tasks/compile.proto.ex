defmodule Mix.Tasks.CompileProto do
  use Mix.Task

  @output_dir "lib/proto"
  @protocol_dir "protocol/protobufs"
  @protocol_files [
    "logger/options.proto",
    "livekit_agent_dispatch.proto",
    "livekit_agent.proto",
    "livekit_egress.proto",
    "livekit_ingress.proto",
    "livekit_metrics.proto",
    "livekit_models.proto",
    "livekit_room.proto",
    "livekit_webhook.proto"
  ]

  @shortdoc "Compiles the protocol buffers"
  def run(_args) do
    # Create output directory if it doesn't exist
    File.mkdir_p!(@output_dir)

    @protocol_files
    |> Enum.map(&Path.join(@protocol_dir, &1))
    |> Enum.map(&exec_sys_cmd/1)
    |> Enum.map(&Mix.shell().info(inspect(&1)))
  end

  defp exec_sys_cmd(proto_file_path) do
    params = [
      "--elixir_out=#{@output_dir}",
      "--proto_path=#{@protocol_dir}",
      proto_file_path
    ]

    case System.cmd("protoc", params, stderr_to_stdout: true) do
      {_, 0} -> {:ok, proto_file_path}
      {error, _} -> {:error, proto_file_path, "Error: #{error}"}
    end
  end
end

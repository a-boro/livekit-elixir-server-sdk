defmodule Logger.PbExtension do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0"

  extend Google.Protobuf.FieldOptions, :redact, 50001, optional: true, type: :bool

  extend Google.Protobuf.FieldOptions, :redact_format, 50002,
    optional: true,
    type: :string,
    json_name: "redactFormat"
end

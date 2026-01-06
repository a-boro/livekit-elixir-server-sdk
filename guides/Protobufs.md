# Protobufs

ExLivekit is designed in a way that using protobuf structs is very limited. All protobuf modules start with `Livekit` and appear in service responses or in some more advanced configurations.

## Protobuf Field Types

When working with protobuf structs in ExLivekit, there are two special field types that require specific handling: `oneof` fields and `enum` fields.

### Oneof Fields

`oneof` fields represent mutually exclusive options in a protobuf message. In Elixir, you set a `oneof` field using a tuple syntax: `{:field_name, value}`.

**In Protobuf File:**

```elixir
defmodule Livekit.WebEgressRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :output, 0
  oneof :options, 1

  field :url, 1, type: :string
  field :preset, 7, type: Livekit.EncodingOptionsPreset, enum: true, oneof: 1
  field :advanced, 8, type: Livekit.EncodingOptions, oneof: 1
  field :file, 4, type: Livekit.EncodedFileOutput, oneof: 0
  field :stream, 5, type: Livekit.StreamOutput, oneof: 0
end
```

**Usage Example:**

```elixir
# For a struct with a oneof field named :options
# that can be either :preset (enum) or :advanced (struct)

# Using a preset (enum atom)
request = %Livekit.RoomCompositeEgressRequest{
  room_name: "my_room",
  options: {:preset, :H264_1080P_30}
}

# Using advanced options (struct)
advanced_opts = %Livekit.EncodingOptions{
  width: 1920,
  height: 1080,
  video_codec: :H264_HIGH
}

request = %Livekit.RoomCompositeEgressRequest{
  room_name: "my_room",
  options: {:advanced, advanced_opts}
}
```

**Key Points:**

- The tuple format is `{:atom_field_name, value}`
- Only one field in a `oneof` group can be set at a time
- The atom in the tuple must match the field name in the protobuf definition

### Enum Fields

Enum fields can be used in two ways:

1. **As atoms directly** - You can use the enum value as an atom
2. **As part of the protobuf struct** - The enum module can be referenced, but atoms are preferred

**In Protobuf File:**

```elixir
# Enum module definition
defmodule Livekit.EncodedFileType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :DEFAULT_FILETYPE, 0
  field :MP4, 1
  field :OGG, 2
  field :MP3, 3
end

# Enum field in a struct
defmodule Livekit.EncodedFileOutput do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :file_type, 1, type: Livekit.EncodedFileType, json_name: "fileType", enum: true
  field :filepath, 2, type: :string
end
```

**Usage Example:**

```elixir
# Using enum as an atom directly (recommended)
%Livekit.EncodedFileOutput{
  filepath: "output.mp4",
  file_type: :MP4  # atom from Livekit.EncodedFileType enum
}

%Livekit.EncodedFileOutput{
  filepath: "output.mp4",
  file_type: 1  # integer representing index
}
```

**Key Points:**

- Enum values are atoms (e.g., `:MP4`, `:EGRESS_ACTIVE`, `:AUDIO`) or integers representing indexes of a field
- You can use atoms directly without referencing the enum module
- When used in `oneof` fields, enums still use the tuple syntax: `{:preset, :H264_1080P_30}`

### Common Patterns

**Combining oneof and enum:**

```elixir
# In Livekit.WebEgressRequest, :options is a oneof field
# that can be either :preset (enum) or :advanced (struct)

request = %Livekit.WebEgressRequest{
  url: "https://example.com",
  options: {:preset, :H264_720P_30}  # enum in oneof
}

# Or with advanced options
request = %Livekit.WebEgressRequest{
  url: "https://example.com",
  options: {:advanced, %Livekit.EncodingOptions{...}}  # struct in oneof
}
```

**Reading oneof fields:**

When reading protobuf structs with `oneof` fields, the field will be a tuple:

```elixir
case request.options do
  {:preset, preset_atom} ->
    IO.puts("Using preset: #{preset_atom}")

  {:advanced, %Livekit.EncodingOptions{} = opts} ->
    IO.puts("Using advanced options")

  nil ->
    IO.puts("No options set")
end
```

### Repeated Fields

Repeated fields represent arrays or lists of values. In Elixir, they are represented as lists.

**In Protobuf File:**

```elixir
defmodule Livekit.DataPacket do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :destination_identities, 5,
    repeated: true,
    type: :string,
    json_name: "destinationIdentities"

  field :tracks, 4, repeated: true, type: Livekit.TrackInfo
end
```

**Usage Example:**

```elixir
# Repeated string field
packet = %Livekit.DataPacket{
  destination_identities: ["user1", "user2", "user3"]
}

# Repeated struct field
participant = %Livekit.ParticipantInfo{
  tracks: [
    %Livekit.TrackInfo{sid: "track1", type: :AUDIO},
    %Livekit.TrackInfo{sid: "track2", type: :VIDEO}
  ]
}
```

### Map Fields

Map fields represent key-value pairs. In Elixir, they are represented as maps.

**In Protobuf File:**

```elixir
defmodule Livekit.ParticipantInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :attributes, 15,
    repeated: true,
    type: Livekit.ParticipantInfo.AttributesEntry,
    map: true,
    deprecated: false
end
```

**Usage Example:**

```elixir
participant = %Livekit.ParticipantInfo{
  attributes: %{
    "role" => "admin",
    "department" => "engineering"
  }
}
```

### Optional Fields

Optional fields (proto3_optional) can be `nil` or have a value. They are useful for distinguishing between unset and explicitly set to default values.

**In Protobuf File:**

```elixir
defmodule Livekit.SomeMessage do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :topic, 5, proto3_optional: true, type: :string
  field :participant, 4, proto3_optional: true, type: Livekit.ParticipantInfo
end
```

**Usage Example:**

```elixir
# Field can be nil
message = %Livekit.SomeMessage{
  topic: nil
}

# Or have a value
message = %Livekit.SomeMessage{
  topic: "my_topic"
}
```

### Basic Field Types

Basic field types include strings, integers, booleans, and bytes.

**In Protobuf File:**

```elixir
# Example with various basic types
defmodule Livekit.RoomCompositeEgressRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :room_name, 1, type: :string, json_name: "roomName"
  field :audio_only, 3, type: :bool, json_name: "audioOnly"
end

defmodule Livekit.DataPacket do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :sequence, 16, type: :uint32
  field :participant_sid, 17, type: :string, json_name: "participantSid"
end

defmodule Livekit.ParticipantInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :joined_at, 6, type: :int64, json_name: "joinedAt"
end

defmodule Livekit.SpeakerInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :level, 2, type: :float
end

defmodule Livekit.EncryptedPacket do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :iv, 2, type: :bytes
end
```

**Usage Example:**

```elixir
# String and bool
request = %Livekit.RoomCompositeEgressRequest{
  room_name: "my_room",        # :string
  audio_only: true             # :bool
}

# Unsigned integer
packet = %Livekit.DataPacket{
  sequence: 42                  # :uint32
}

# Signed integer
participant = %Livekit.ParticipantInfo{
  joined_at: 1234567890         # :int64
}

# Float
speaker = %Livekit.SpeakerInfo{
  level: 0.85                   # :float
}

# Bytes
encrypted = %Livekit.EncryptedPacket{
  iv: <<1, 2, 3, 4>>            # :bytes
}
```

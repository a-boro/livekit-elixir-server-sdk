# ExLivekit

<!-- MDOC !-->

> **Note:** This is not an official LiveKit SDK. This is a community-maintained Elixir client. While this is an early version, it is currently being used in production by the maintainer in a large-scale system working with LiveKit. Use on your own risk.

## Getting Started

Add `ex_livekit` to your dependencies. By default, `hackney` is used as the HTTP client:

```elixir
def deps do
  [
    {:ex_livekit, git: "https://github.com/a-boro/livekit-elixir-server-sdk.git", branch: "main"},
    {:hackney, "~> 1.22"}
  ]
end
```

If you prefer to use `finch` instead of `hackney`, see the [Http Client Configuration](#http-client-configuration) section below.

### Naming Conventions

This library uses two types of module names:

- **`ExLivekit`** - Modules that are part of this library's logic (e.g., `ExLivekit.Client`, `ExLivekit.AccessToken`, `ExLivekit.RoomService`)
- **`Livekit`** - Modules generated from Protobuf definitions (e.g., `Livekit.Room`, `Livekit.Participant`, `Livekit.StreamOutput`)

The `Livekit` modules contain the data structures and types defined in the LiveKit protocol buffers, while `ExLivekit` modules contain the library's implementation and business logic.

## Configuration

### Livekit Credentials Configuration

The `api_key` and `api_secret` can be provided in the config file:

```elixir
  config :ex_livekit,
    api_key: <Livekit API KEY>,
    api_secret: <Livekit API SECRET>
```

Alternatively, they can be provided during `AccessToken` or `Client` initialization as part of the `opts` config:

```elixir
  # AccessToken example
  token = ExLivekit.AccessToken.new(
    api_key: "your_api_key",
    api_secret: "your_api_secret"
  )

  # Client example
  client = ExLivekit.Client.new(
    host: "https://api.livekit.io",
    api_key: "your_api_key",
    api_secret: "your_api_secret"
  )
```

If neither the config file nor the opts are provided, an exception will be raised.

### Livekit Webhook Configuration

You can define `api_key` and `api_secret` in the webhook config:

```elixir
  config :ex_livekit, :webhook,
    api_key: <Livekit API KEY>,
    api_secret: <Livekit API SECRET>
```

If not provided in the webhook config, the `api_key` and `api_secret` from the main configuration above will be used.
If none are defined, an exception will be raised.

### Http Client Configuration

By default, `ex_livekit` uses `hackney` as the HTTP client. You can customize Hackney's behavior or switch to `finch`.

#### Using Hackney (Default)

Hackney is the default HTTP client. You can customize its options:

```elixir
  config :ex_livekit,
    hackney_opts: [timeout: 30_000, connect_timeout: 10_000],
    hackney_pool_opts: [timeout: 30_000, max_connections: 50]
```

Default values:

- `hackney_opts`: `[timeout: 30_000]`
- `hackney_pool_opts`: `[timeout: 30_000, max_connections: 50]`

See the [Hackney documentation](https://hexdocs.pm/hackney/) for available options.

#### Using Finch

To use `finch` instead of `hackney`, you need to:

1. Add `finch` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    ...
    {:finch, "~> 0.18"}
  ]
end
```

2. Configure `ex_livekit` to use Finch:

```elixir
  config :ex_livekit,
    http_client: :finch
```

3. Optionally customize Finch options:

```elixir
  config :ex_livekit,
    http_client: :finch,
    finch_opts: [receive_timeout: 30_000],
    finch_pool_opts: [size: 10]
```

Default values:

- `finch_opts`: `[receive_timeout: 30_000]`
- `finch_pool_opts`: `[]` # default Finch values

See the [Finch documentation](https://hexdocs.pm/finch/) for available options.

## Access Token

Access tokens are used to authenticate participants in LiveKit rooms. You can create tokens using the configuration from your config file or by providing credentials directly.

### Basic Token Creation

Create a token using credentials from your config file:

```elixir
token = ExLivekit.AccessToken.new()
```

Or provide credentials directly:

```elixir
token = ExLivekit.AccessToken.new(
  api_key: "your_api_key",
  api_secret: "your_api_secret"
)
```

### Building a Complete Token

Build a token with identity, grants, and other properties:

```elixir
jwt_token =
  ExLivekit.AccessToken.new()
  |> ExLivekit.AccessToken.add_identity("user123")
  |> ExLivekit.AccessToken.add_name("John Doe")
  |> ExLivekit.AccessToken.add_metadata("user metadata")
  |> ExLivekit.AccessToken.add_ttl(3600)  # Token expires in 1 hour (default)
  |> ExLivekit.AccessToken.add_grants(%ExLivekit.Grants.VideoGrant{
    room_join: true,
    room: "my-room",
    can_publish: true,
    can_subscribe: true
  })
  |> ExLivekit.AccessToken.to_jwt()
```

### Video Grants

Video grants control room and participant permissions:

```elixir
# Using a VideoGrant struct
video_grant = %ExLivekit.Grants.VideoGrant{
  room_create: true,
  room_join: true,
  room: "my-room",
  can_publish: true,
  can_subscribe: true
}

token = ExLivekit.AccessToken.new()
  |> ExLivekit.AccessToken.add_grants(video_grant)
```

Or use a map (which will be merged with existing grants):

```elixir
token = ExLivekit.AccessToken.new()
  |> ExLivekit.AccessToken.add_grants(%{room_create: true, room_join: true})
```

### Additional Grant Types

Add other grant types as needed:

```elixir
token = ExLivekit.AccessToken.new()
  |> ExLivekit.AccessToken.add_sip_grants(%ExLivekit.Grants.SIPGrant{
    admin: true,
    call: true
  })
  |> ExLivekit.AccessToken.add_inference_grants(%ExLivekit.Grants.InferenceGrant{
    perform: true
  })
  |> ExLivekit.AccessToken.add_observability_grants(%ExLivekit.Grants.ObservabilityGrant{
    write: true
  })
```

### Participant Kinds

Set the participant kind:

```elixir
token = ExLivekit.AccessToken.new()
  |> ExLivekit.AccessToken.add_kind(:agent)  # Options: :standard, :egress, :ingress, :sip, :agent
```

### Converting to JWT

Once your token is configured, convert it to a JWT string:

```elixir
jwt_token = ExLivekit.AccessToken.to_jwt(token)
```

The JWT token can then be used to authenticate with LiveKit services.

## Usage

All services in `ex_livekit` require a `Client` instance to make API requests. The first step is to create a client, then you can use it with any service.

### Creating a Client

Create a client using credentials from your config file:

```elixir
client = ExLivekit.Client.new()
```

Or provide credentials directly:

```elixir
client = ExLivekit.Client.new(
  host: "https://api.livekit.io",
  api_key: "your_api_key",
  api_secret: "your_api_secret"
)
```

### Room Service

The Room Service is the most popular way to interact with LiveKit. It provides functionality to manage rooms, participants, and room-related operations.

#### Creating a Room

```elixir
{:ok, room} = ExLivekit.RoomService.create_room(client, "my-room")
```

With additional options:

```elixir
{:ok, room} = ExLivekit.RoomService.create_room(client, "my-room",
  max_participants: 50,
  empty_timeout: 300,
  metadata: "Room metadata"
)
```

#### Listing Rooms

```elixir
{:ok, response} = ExLivekit.RoomService.list_rooms(client)
```

Filter by room names:

```elixir
{:ok, response} = ExLivekit.RoomService.list_rooms(client, names: ["room1", "room2"])
```

#### Deleting a Room

```elixir
:ok = ExLivekit.RoomService.delete_room(client, "my-room")
```

#### Managing Participants

List participants in a room:

```elixir
{:ok, response} = ExLivekit.RoomService.list_participants(client, "my-room")
```

Get a specific participant:

```elixir
{:ok, participant} = ExLivekit.RoomService.get_participant(client, "my-room", "participant_identity")
```

Remove a participant:

```elixir
:ok = ExLivekit.RoomService.remove_participant(client, "my-room", "participant_identity")
```

Update participant metadata:

```elixir
{:ok, participant} = ExLivekit.RoomService.update_participant(client, "my-room", "participant_identity",
  metadata: "new metadata",
  name: "New Name"
)
```

#### Updating Room Metadata

```elixir
{:ok, room} = ExLivekit.RoomService.update_room_metadata(client, "my-room", "updated metadata")
```

### Ingress Service

The Ingress Service allows you to bring external media streams into LiveKit rooms.

#### Creating an Ingress

```elixir
{:ok, ingress} = ExLivekit.IngressService.create_ingress(client,
  input_type: :RTMP_INPUT,
  room_name: "my-room",
  participant_identity: "streamer",
  participant_name: "Streamer Name"
)
```

#### Listing Ingresses

```elixir
{:ok, response} = ExLivekit.IngressService.list_ingresses(client)
```

Filter by room or ingress ID:

```elixir
{:ok, response} = ExLivekit.IngressService.list_ingresses(client,
  room_name: "my-room",
  ingress_id: "ingress_id"
)
```

#### Updating an Ingress

```elixir
{:ok, ingress} = ExLivekit.IngressService.update_ingress(client,
  ingress_id: "ingress_id",
  name: "Updated Name",
  participant_metadata: "Updated metadata"
)
```

#### Deleting an Ingress

```elixir
{:ok, ingress} = ExLivekit.IngressService.delete_ingress(client, "ingress_id")
```

### Egress Service

The Egress Service allows you to record or stream room content to external destinations.

#### Starting Room Composite Egress

Record or stream an entire room:

```elixir
output = %Livekit.StreamOutput{
  protocol: :RTMP_INPUT,
  urls: ["rtmp://example.com/live"]
}

{:ok, egress} = ExLivekit.EgressService.start_room_composite_egress(client, "my-room", output)
```

#### Starting Participant Egress

Record or stream a specific participant:

```elixir
output = %Livekit.EncodedFileOutput{
  file_type: :MP4,
  filepath: "/path/to/output.mp4"
}

{:ok, egress} = ExLivekit.EgressService.start_participant_egress(
  client,
  "my-room",
  "participant_identity",
  output
)
```

#### Listing Egresses

```elixir
{:ok, response} = ExLivekit.EgressService.list_egress(client)
```

Filter by room or egress ID:

```elixir
{:ok, response} = ExLivekit.EgressService.list_egress(client,
  room_name: "my-room",
  egress_id: "egress_id",
  active: true
)
```

#### Stopping an Egress

```elixir
{:ok, egress} = ExLivekit.EgressService.stop_egress(client, "egress_id")
```

## License

The MIT License (MIT)

Copyright (c) 2014-2020 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

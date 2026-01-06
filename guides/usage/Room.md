# Room Service

The Room Service is the most popular way to interact with LiveKit. It provides functionality to manage rooms, participants, and room-related operations.

[Livekit API Documentation](https://docs.livekit.io/reference/other/roomservice-api/)

### Creating a Room

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

### Listing Rooms

```elixir
{:ok, response} = ExLivekit.RoomService.list_rooms(client)
```

Filter by room names:

```elixir
{:ok, response} = ExLivekit.RoomService.list_rooms(client, names: ["room1", "room2"])
```

### Deleting a Room

```elixir
:ok = ExLivekit.RoomService.delete_room(client, "my-room")
```

### Managing Participants

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

### Updating Room Metadata

```elixir
{:ok, room} = ExLivekit.RoomService.update_room_metadata(client, "my-room", "updated metadata")
```

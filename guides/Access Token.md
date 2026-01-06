# Access Token

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
  |> ExLivekit.AccessToken.add_identity("user123") # unique id of the user
  |> ExLivekit.AccessToken.add_name("John Doe") # a name of participants, visible in the room
  |> ExLivekit.AccessToken.add_ttl(3600)  # Token expires in 1 hour (default)
  |> ExLivekit.AccessToken.add_grants(%ExLivekit.Grants.VideoGrant{
    room_join: true,
    room: "my-room"
  })
  |> ExLivekit.AccessToken.to_jwt()

  # To create a token for participants joining a room, the identity and room (room's name) must be provided.
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

### Converting to JWT

Once your token is configured, convert it to a JWT string:

```elixir
jwt_token = ExLivekit.AccessToken.to_jwt(token)
```

The JWT token can then be used to authenticate with LiveKit services.

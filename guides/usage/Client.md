# Client

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

That's created client can be used for any service like: `RoomService`, `IngressService`, etc.

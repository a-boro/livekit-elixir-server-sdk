# Getting Started

## Setup

1. Add `ex_livekit` to your dependencies. By default, `hackney` is used as the HTTP client:

```elixir
def deps do
  [
    {:ex_livekit, git: "https://github.com/a-boro/livekit-elixir-server-sdk.git", branch: "main"}
  ]
end
```

2. Add `hackney` to use default HTTP client

```elixir
    def deps do
    [
      ...
      {:hackney, "~> 1.22"}
    ]
```

If you prefer to use `finch` instead of `hackney`, see the [Http Client Configuration](/guides/Configuration.md/#http-client-configuration) section below.

## Naming Conventions

This library uses two types of module names:

- **`ExLivekit`** - Modules that are part of this library's logic (e.g., `ExLivekit.Client`, `ExLivekit.AccessToken`, `ExLivekit.RoomService`)
- **`Livekit`** - Modules generated from Protobuf definitions (e.g., `Livekit.Room`, `Livekit.Participant`, `Livekit.StreamOutput`)

The `Livekit` modules contain the data structures and types defined in the LiveKit protocol buffers, while `ExLivekit` modules contain the library's implementation and business logic.

## External Documentation

To learn more, visit:

- [Livekit Documentation](https://docs.livekit.io/transport/)
- [Livekit API Documentation](https://docs.livekit.io/reference/other/roomservice-api/)
- [Livekit Protocol Git Repository](https://github.com/livekit/protocol)
- [Livekit Server Git Repository](https://github.com/livekit/livekit)

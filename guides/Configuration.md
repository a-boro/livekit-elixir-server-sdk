# Configuration

## Credentials Configuration

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

## Webhook Configuration

You can define `api_key` and `api_secret` in the webhook config:

```elixir
  config :ex_livekit, :webhook,
    api_key: <Livekit API KEY>,
    api_secret: <Livekit API SECRET>
```

If not provided in the webhook config, the `api_key` and `api_secret` from the main configuration above will be used.
If none are defined, an exception will be raised.

## Http Client Configuration

By default, `ex_livekit` uses `hackney` as the HTTP client. You can customize Hackney's behavior or switch to `finch`.

### Using Hackney (Default)

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

### Using Finch

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

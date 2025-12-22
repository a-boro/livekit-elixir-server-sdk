defmodule ExLivekit.MixProject do
  use Mix.Project

  @source_url "https://github.com/a-boro/livekit-elixir-server-sdk"
  @version "0.0.1"

  def project do
    [
      app: :ex_livekit,
      version: @version,
      elixir: "~> 1.17",
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps(),
      description: description(),
      docs: docs(),
      name: "ExLivekit"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ExLivekit, []}
    ]
  end

  defp description do
    "Elixir SDK for LiveKit Server"
  end

  defp deps do
    [
      # http clients
      {:hackney, "~> 1.22", optional: true},
      {:finch, "~> 0.2", optional: true},

      # data formats
      {:joken, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:protobuf, "~> 0.14.1"},

      # devtools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:bypass, "~> 2.0", only: [:test]}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      formatters: ["html"],
      output: "doc",
      source_ref: "main",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: &String.match?(&1, ~r"^Livekit\.*"),
      groups_for_modules: [
        "Access Token": [
          ExLivekit.AccessToken,
          ExLivekit.TokenVerifier
        ],
        "Livekit Services": [
          ExLivekit.RoomService,
          ExLivekit.EgressService,
          ExLivekit.IngressService,
          ExLivekit.AgentDispatchService,
          ExLivekit.Webhook
        ],
        "Access Token Grants": [
          ExLivekit.Grants,
          ExLivekit.Grants.ClaimGrant,
          ExLivekit.Grants.InferenceGrant,
          ExLivekit.Grants.ObservabilityGrant,
          ExLivekit.Grants.SIPGrant,
          ExLivekit.Grants.VideoGrant
        ],
        "Livekit Client": [
          ExLivekit.Client,
          ExLivekit.Client.Finch,
          ExLivekit.Client.Hackney,
          ExLivekit.Client.HTTPClient
        ],
        "Livekit Protobufs": [
          ~r"^Livekit\.*"
        ]
      ]
    ]
  end
end

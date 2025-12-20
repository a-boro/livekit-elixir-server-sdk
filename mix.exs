defmodule ExLivekit.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_livekit,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {ExLivekit, []}
    ]
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
      {:bypass, "~> 2.0", only: [:test]}
    ]
  end
end

defmodule ExLivekit.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_livekit,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:joken, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:protobuf, "~> 0.14.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end

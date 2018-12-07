defmodule V3Api.Mixfile do
  use Mix.Project

  def project do
    [
      app: :v3_api,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.2",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :httpoison, :json_api, :sentry],
      mod: {V3Api.Application, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:poison, "~> 2.2", override: true},
      {:hackney, "~> 1.8.0"},
      {:excoveralls, "~> 0.5", only: :test},
      {:bypass, "~> 0.8", only: :test},
      {:server_sent_event_stage, "~> 0.3"},
      {:gen_stage, "~> 0.13"},
      {:json_api, in_umbrella: true},
      {:util, in_umbrella: true},
      {:sentry, github: "mbta/sentry-elixir", tag: "6.0.0"}
    ]
  end
end

defmodule GoTrue.MixProject do
  use Mix.Project

  @source_url "https://github.com/joshnuss/gotrue-elixir"

  def project do
    [
      app: :gotrue,
      version: "0.2.1",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: [
        maintainers: ["Joshua Nussbaum"],
        licenses: ["MIT"],
        links: %{GitHub: @source_url}
      ],
      description: "GoTrue client for Elixir",
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.7.0"},
      {:hackney, "~> 1.18.2"},
      {:jason, ">= 1.4.1"},
      {:joken, "~> 2.6", only: :test},
      {:ex_doc, "~> 0.30.6", only: :dev}
    ]
  end

  defp aliases do
    [
      "test.setup": [
        "cmd docker compose -f infra/docker-compose.yml down",
        "cmd docker compose -f infra/docker-compose.yml pull",
        "cmd docker compose -f infra/docker-compose.yml up -d",
        "cmd sleep 30"
      ],
      "test.cleanup": [
        "cmd docker compose -f infra/docker-compose.yml down -v --remove-orphans"
      ]
    ]
  end
end

defmodule GoTrue.MixProject do
  use Mix.Project

  @source_url "https://github.com/joshnuss/gotrue-elixir"

  def project do
    [
      app: :gotrue,
      version: "0.2.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: [
        maintainers: ["Joshua Nussbaum"],
        licenses: ["MIT"],
        links: %{GitHub: @source_url}
      ],
      description: "GoTrue client for Elixir"
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.7.0"},
      {:hackney, "~> 1.18.2"},
      {:jason, ">= 1.4.1"},
      {:ex_doc, "~> 0.30.6", only: :dev}
    ]
  end
end

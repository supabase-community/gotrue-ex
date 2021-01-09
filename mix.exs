defmodule Gotrue.MixProject do
  use Mix.Project

  def project do
    [
      app: :gotrue,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.16.0"},
      {:jason, ">= 1.0.0"}
    ]
  end
end

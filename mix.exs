defmodule Alembic.Mixfile do
  use Mix.Project

  # Functions

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :poison]]
  end

  def project do
    [
      app: :alembic,
      build_embedded: Mix.env == :prod,
      deps: deps,
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      name: "Alembic",
      source_url: "https://github.com/C-S-D/alembic",
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: Coverex.Task],
      version: "0.0.1"
    ]
  end

  ## Private Functions

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # static code analysis for style and consistency
      {:credo, "~> 0.3.13", only: [:dev, :test]},
      # test coverge tool.  Allow `--cover` option for `mix test`
      {:coverex, "~> 1.4", only: :test},
      # success type checker: ensures @type and @spec are valid
      {:dialyze, "~> 0.2.1", only: :dev},
      # markdown to HTML converter for ex_doc
      {:earmark, "~> 0.2.1", only: :dev},
      # documentation generation
      {:ex_doc, "~> 0.11.5", only: :dev},
      # documentation coverage
      {:inch_ex, "~> 0.5.1", only: [:dev, :test]},
      # formats test output for CircleCI
      {:junit_formatter, "~> 1.0", only: :test},
      # JSON decode and encoding.  Protocols are implemented for Alembic.* structs
      {:poison, "~> 2.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end

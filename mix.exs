defmodule Alembic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :alembic,
      build_embedded: Mix.env == :prod,
      deps: deps,
      elixir: "~> 1.2",
      name: "Alembic",
      source_url: "https://github.com/C-S-D/alembic",
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: Coverex.Task],
      version: "0.0.1"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

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
      # test coverge tool.  Allow `--cover` option for `mix test`
      {:coverex, "~> 1.4", only: :test},
      # markdown to HTML converter for ex_doc
      {:earmark, "~> 0.2.1", only: :dev},
      # documentation generation
      {:ex_doc, "~> 0.11.5", only: :dev},
      # formats test output for CircleCI
      {:junit_formatter, "~> 1.0", only: :test}
    ]
  end
end

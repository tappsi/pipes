defmodule Pipes.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :pipes,
     name: "Pipes",
     source_url: "https://github.com/tappsi/pipes",
     homepage_url: "https://github.com/tappsi/pipes",
     version: @version,
     description: description,
     docs: docs,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :amqp, :poolboy],
     mod: {Pipes, []}]
  end

  def description do
    "Pooled AMQP consumers and publishers"
  end

  defp docs do
    [source_ref: "v#{@version}",
     main: "Pipes",
     extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md"]]
  end

  defp deps do
    [{:amqp, "~> 0.1"},
     {:poolboy, "~> 1.5"},

     # Documentation
     {:ex_doc, "~> 0.10", only: :docs},
     {:earmark, "~> 0.1", only: :docs}]
  end
end

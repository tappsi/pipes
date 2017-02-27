defmodule Pipes.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [app: :pipes,
     name: "Pipes",
     source_url: "https://github.com/tappsi/pipes",
     homepage_url: "https://github.com/tappsi/pipes",
     version: @version,
     description: description(),
     docs: docs(),
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
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
    [{:amqp, "~> 0.2.0-pre.2"},
     {:poolboy, "~> 1.5.1"},

     # Documentation
     {:ex_doc, "~> 0.15", only: :docs, runtime: false},
     {:earmark, "~> 1.1.1", only: :docs, runtime: false}]
  end
end

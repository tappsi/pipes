defmodule Pipes.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :pipes,
     name: "Pipes",
     version: @version,
     docs: docs(),
     description: description(),
     package: package(),
     source_url: "https://github.com/tappsi/pipes",
     homepage_url: "https://github.com/tappsi/pipes",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Pipes.Application, []}]
  end

  def description do
    "Pooled AMQP consumers and publishers"
  end

  defp deps do
    [{:amqp, "~> 0.2.0-pre.2"},
     {:poolboy, "~> 1.5.1"},

     # Documentation
     {:ex_doc, "> 0.0.0", only: :docs},
     {:earmark, "> 0.0.0", only: :docs}]
  end

  defp docs do
    [source_ref: "v#{@version}",
     main: "Pipes",
     extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md"]]
  end

  defp package do
    [files: ~w(lib test mix.exs README.md LICENSE VERSION),
     maintainers: ["Ricardo Lanziano", "Oscar Moreno"],
     licences: ["MIT"],
     links: %{"GitHub" => "https://github.com/tappsi/pipes"}]
  end
end

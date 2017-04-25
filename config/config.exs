use Mix.Config

if Mix.env == :test do
  config :pipes,
    manager: Pipes.Broker.DummyManager,
    connection: Pipes.Broker.DummyConnection
end

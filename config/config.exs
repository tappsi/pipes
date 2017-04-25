use Mix.Config

config :pipes,
  manager: Pipes.Broker.DummyManager,
  connection: Pipes.Broker.DummyConnection

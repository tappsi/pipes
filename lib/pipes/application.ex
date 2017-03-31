defmodule Pipes.Application do
  @moduledoc false

  use Application

  alias Pipes.{Broker, Consumer, Producer}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Broker.Supervisor, []),
      supervisor(Consumer.Supervisor, []),
      supervisor(Producer.Supervisor, []),
    ]

    opts = [strategy: :one_for_one, name: Pipes.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

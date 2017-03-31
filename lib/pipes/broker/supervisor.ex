defmodule Pipes.Broker.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: Pipes.BrokerSupervisor)
  end

  def init(_args) do
    children = [worker(Pipes.Broker.Connection, [], restart: :transient)]
    supervise(children, strategy: :simple_one_for_one)
  end
end

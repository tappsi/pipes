defmodule Pipes.Consumer.Supervisor do
  use Supervisor

  @sup_name Consumer.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @sup_name)
  end

  def init(_opts) do
    children = [worker(Pipes.Consumer.Worker, [], restart: :transient)]
    supervise(children, strategy: :simple_one_for_one)
  end
end

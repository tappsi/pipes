defmodule Pipes.Supervisor do
  @moduledoc false
  use Supervisor

  def specs(sup, pipeline) do
    supervisor(sup, [pipeline], id: pipeline.name)
  end

  # Supervisor callbacks

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    opts = [strategy: :one_for_one]
    supervise([], opts)
  end
end

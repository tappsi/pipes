defmodule Pipes.Producer.Supervisor do
  use Supervisor

  @sup_name Producer.Supervisor
  @worker_module Pipes.Producer.Worker

  def start_pool(opts) do
    size = opts[:max_workers] || 1
    pool_name = "#{opts[:name]}_producer" |> String.to_atom()
    pool_specs = Pipes.config_pool(pool_name, @worker_module, size)
		Supervisor.start_child(@sup_name,
                           :poolboy.child_spec(pool_name, pool_specs, opts))
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @sup_name)
  end

  def init(_opts) do
    supervise([], strategy: :one_for_one)
  end
end

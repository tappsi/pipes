defmodule Pipes.Pipeline.Supervisor do
  @moduledoc false
  use Supervisor

  alias Pipes.Pipeline

  @pool_size 5

  # Supervisor callbacks

  def start_link(pipeline, opts \\ []) do
    Supervisor.start_link(__MODULE__, [pipeline, opts])
  end

  def init([pipeline, opts]) do
    conn_pool = pipeline.name <> "_connections" |> String.to_atom
    pub_pool  = pipeline.name <> "_publishers"  |> String.to_atom

    conn_pool_size = opts[:pool_size] || @pool_size
    pub_pool_size  = opts[:pool_size] || @pool_size

    conn_pool_spec = pool_spec(conn_pool, Pipes.Connection, conn_pool_size)
    pub_pool_spec  = pool_spec(pub_pool, Pipes.Publisher, pub_pool_size)

    children = [
      :poolboy.child_spec(conn_pool, conn_pool_spec, pipeline),
      :poolboy.child_spec(pub_pool, pub_pool_spec, conn_pool),
      worker(Pipeline.Server, [pipeline, conn_pool, pub_pool, opts])
    ]

    sup_opts = [strategy: :one_for_one]
    supervise(children, sup_opts)
  end

  # Internal functions

  defp pool_spec(name, module, size, strategy \\ :fifo) do
    [name: {:local, name},
     worker_module: module,
     size: size || @pool_size,
     strategy: strategy,
     max_overflow: 0]
  end
end

defmodule Pipes.Pipeline.Server do
  @moduledoc false
  require Logger

  use AMQP
  use GenServer

  alias Pipes.Pipe

  # GenServer callbacks

  def start_link(pipeline, conn_pool, pub_pool, opts) do
    server_name = {:local, pipeline.name <> "_server" |> String.to_atom}
    server_args = [pipeline, server_name, conn_pool, pub_pool, opts]

    GenServer.start_link(__MODULE__, server_args, name: server_name)
  end

  def init([pipeline, pipeline_server, conn_pool, pub_pool, opts]) do
    Process.flag(:trap_exit, true)

    consumers = :ets.new(:consumers, [:set, :private, :protected])

    state =
      %{server: pipeline_server, connections: conn_pool,
        publishers: pub_pool, opts: opts, pipeline: pipeline,
        consumers: consumers}

    {:ok, state}
  end

  def handle_call({:add_pipe, module}, _from, state) do
    case Pipe.start(state.connections, state.pipeline, module) do
      {:ok, pipe} ->
        :ok = register_new_pipe(state.consumers, module, pipe)

        Process.monitor(pipe)
        {:reply, {:ok, pipe}, state}
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:remove_pipe, module}, _from, state) do
    {:ok, pipe} = unregister_pipe(state.consumers, module)
    Process.demonitor(pipe)
    :ok = Pipe.stop(pipe)

    {:reply, :ok, state}
  end

  def handle_call(:all_pipes, _from, state) do
    pipes = :ets.match_object(state.consumers, :_)
    {:reply, pipes, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error "Consumer died: #{inspect reason}"
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error "Consumer exited: #{inspect reason}"
    {:noreply, state}
  end

  def terminate(reason, _state) do
    Logger.error "Terminating! #{inspect reason}"
    :ok
  end

  # Internal functions

  defp register_new_pipe(consumers, module, pid) do
    true = :ets.insert(consumers, {module, pid})
    :ok
  end

  defp unregister_pipe(consumers, module) do
    case :ets.lookup(consumers, module) do
      [{^module, pid}] ->
        :ets.delete(consumers, module)
        {:ok, pid}
      [] ->
        {:error, :not_found}
    end
  end
end

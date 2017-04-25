defmodule Pipes.Producer.Worker do
  use GenServer

  require Logger

  @max_retries 5
  @amqp_sup Pipes.BrokerSupervisor
  @manager Application.get_env(:pipes, :manager, Pipes.Broker.Manager)

  # API

  @doc "Given a string as `payload`, uses the pool of workers to publish
  a message to the broker"
  def publish(pool_name, payload) do
    do_publish(pool_name, 0, {:publish, payload})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts])
  end

  # GenServer callbacks

  def init([opts]) do
    Process.flag(:trap_exit, true)
    send(self(), :prepare_producer)
    exchange = get_in(opts, [:amqp, :exchange])
    {:ok, %{channel: nil, chann_ref: nil, exchange: exchange, config: opts}}
  end

  def handle_call({:publish, payload}, _from, state) do
    {:reply, @manager.publish(state.channel, state.exchange, "", payload), state}
  end

  def handle_info(:prepare_producer, state) do
    {:ok, pid}   = Supervisor.start_child(@amqp_sup, [state.config])
    {:ok, conn}  = GenServer.call(pid, :get_connection)
    {:ok, channel} =
      get_in(state, [:config, :amqp])
      |> @manager.prepare_producer(conn)

    ref = Process.monitor(channel.pid)
    {:noreply, %{state| channel: channel, chann_ref: ref}}
  end
  def handle_info({:DOWN, _ref, :process, pid, reason},
  %{channel: %{pid: pid}, ref: ref} = state) do
    Logger.error "Channel down: #{inspect reason}"
    Process.demonitor(ref)
    {:stop, {:shutdown, reason}, state}
  end
  def handle_info(message, state) do
    Logger.warn "Unhandled message: #{inspect message}"
    {:noreply, state}
  end

  # Internal functions

  defp do_publish(pool, retry_count, msg) do
    case :poolboy.transaction(pool, &GenServer.call(&1, msg)) do
      :ok -> :ok
      :error when retry_count < @max_retries ->
        do_publish(pool, retry_count - 1, msg)
      _ -> :error
    end
  end
end

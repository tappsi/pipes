defmodule Pipes.Producer.Worker do
  use GenServer
  use AMQP

  require Logger

  @exchange_opts [durable: true, auto_delete: false]
  @max_retries 5
  @amqp_sup Pipes.BrokerSupervisor

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
    {:ok, %{channel: nil, chann_ref: nil, exchange: nil, config: opts}}
  end

  def handle_call({:publish, payload}, _from, state) do
    {:reply, Basic.publish(state.channel, state.exchange, "", payload), state}
  end

  def handle_info(:prepare_producer, state) do
    {:ok, pid}   = Supervisor.start_child(@amqp_sup, [state.config])
    {:ok, conn}  = GenServer.call(pid, :get_connection)
    {:noreply, prepare_producer(state, conn)}
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

  defp prepare_producer(state, conn) do
    {:ok, chann} = Channel.open(conn)
    amqp = state.config[:amqp]
    ref = Process.monitor(chann.pid)

    exchange_opts = amqp[:exchange_opts] || @exchange_opts
    exchange_type = exchange_opts[:type] || :direct
    :ok = Exchange.declare(chann, amqp.exchange, exchange_type, exchange_opts)

    %{state| channel: chann, chann_ref: ref, exchange: amqp.exchange}
  end
end

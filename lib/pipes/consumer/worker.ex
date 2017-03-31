defmodule Pipes.Consumer.Worker do
  use GenServer
  use AMQP

  require Logger

  @prefetch_count 100
  @queue_opts    [durable: true, auto_delete: false]
  @exchange_opts [durable: true, auto_delete: false]
  @consumer_opts [nowait: true, no_ack: true]
  @amqp_sup Pipes.BrokerSupervisor

  # API

  def start_link(opts, consumer) do
    GenServer.start_link(__MODULE__, [opts, consumer])
  end

  # GenServer callbacks

  def init([opts, consumer]) do
    Process.flag(:trap_exit, true)
    send(self(), :prepare_consumer)
    {:ok, %{channel: nil, chann_ref: nil, consumer: consumer, config: opts}}
  end

  def handle_info(:prepare_consumer, state) do
    {:ok, pid}   = Supervisor.start_child(@amqp_sup, [state.config])
    {:ok, conn}  = GenServer.call(pid, :get_connection)
    {:noreply, prepare_consumer(state, conn)}
  end
  def handle_info({:basic_consume_ok, %{consumer_tag: _tag}}, state) do
    {:noreply, state}
  end
  def handle_info({:basic_cancel, %{consumer_tag: _tag}}, state) do
    {:stop, :normal, state}
  end
  def handle_info({:basic_cancel_ok, %{consumer_tag: _tag}}, state) do
    {:noreply, state}
  end
  def handle_info({:basic_deliver, payload, _}, state) do
    spawn(state.consumer, :consume, [payload])
    {:noreply, state}
  end
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{channel: %{pid: pid}, ref: ref} = state) do
    Logger.error "Channel down: #{inspect reason}"
    Process.demonitor(ref)
    {:stop, {:shutdown, reason}, state}
  end
  def handle_info(message, state) do
    Logger.warn "Unhandled message: #{inspect message}"
    {:noreply, state}
  end

  # Internal functions

  defp prepare_consumer(state, conn) do
    {:ok, chann} = Channel.open(conn)
    ref = Process.monitor(chann.pid)

    amqp = state.config[:amqp]

    {:ok, _} = Queue.declare(chann, amqp.queue, amqp[:queue_opts] || @queue_opts)

    exchange_opts = amqp[:exchange_opts] || @exchange_opts
    exchange_type = exchange_opts[:type] || :direct
    :ok = Exchange.declare(chann, amqp.exchange, exchange_type, exchange_opts)

    :ok = Queue.bind(chann, amqp.queue, amqp.exchange)

    :ok = Basic.qos(chann, prefetch_count: @prefetch_count)
    :ok = Confirm.select(chann)

    {:ok, _} = Basic.consume(chann, amqp.queue, self(), @consumer_opts)

    %{state| channel: chann, chann_ref: ref}
  end
end

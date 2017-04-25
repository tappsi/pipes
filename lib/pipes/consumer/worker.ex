defmodule Pipes.Consumer.Worker do
  use GenServer

  require Logger

  @amqp_sup Pipes.BrokerSupervisor
  @manager Application.get_env(:pipes, :manager, Pipes.Broker.Manager)

  # API

  def start_link(opts, consumer) do
    GenServer.start_link(__MODULE__, [opts, consumer])
  end

  # GenServer callbacks

  def init([opts, consumer]) do
    Process.flag(:trap_exit, true)
    send(self(), :prepare_consumer)
    {:ok, %{conn_worker: nil, channel: nil, chann_ref: nil, consumer: consumer, config: opts}}
  end

  def handle_info(:prepare_consumer, state) do
    {:ok, pid}   = Supervisor.start_child(@amqp_sup, [state.config])
    {:ok, conn}  = GenServer.call(pid, :get_connection)
    {:ok, channel} =
      get_in(state, [:config, :amqp])
      |> @manager.prepare_consumer(conn)

    ref = Process.monitor(channel.pid)
    {:noreply, %{state| channel: channel, chann_ref: ref, conn_worker: pid}}
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

  def teminate(_, state) do
    Supervisor.terminate_child(@amqp_sup, state.conn_worker)
    :ok
  end
end

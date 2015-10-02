defmodule Pipes.Pipe do
  @moduledoc ~S"""
  Pipe worker
  """
  require Logger
  use GenServer
  use AMQP

  alias Pipes.Pipeline

  @prefetch_count   100
  @queue_options    [durable: true, auto_delete: false]
  @consumer_options [nowait: true, no_ack: true] # ACK's will be handled by the broker
  @exchange_options [durable: true, auto_delete: false]

  # API

  @doc "Start the pipe worker"
  def start(conn_pool, pipeline, consumer) do
    GenServer.start(__MODULE__, [conn_pool, pipeline, consumer])
  end

  @doc "Stop the pipe worker"
  def stop(pipe) when is_pid(pipe) do
    GenServer.call(pipe, :stop_pipe)
  end

  # GenServer callbacks

  @doc false
  def init([conn_pool, pipeline, consumer]) do
    Process.flag(:trap_exit, true)

    case Pipeline.with_connection(conn_pool, fn conn ->
          {:ok, channel} = Channel.open(conn)

          Process.monitor(channel.pid)

          queue_name     = pipeline.amqp[:queue]
          exchange_name  = pipeline.amqp[:exchange]

          prefetch_count = pipeline.amqp[:prefetch_count] || @prefetch_count
          queue_opts     = pipeline.amqp[:queue_opts]     || @queue_options
          consume_opts   = pipeline.amqp[:consume_opts]   || @consumer_options
          exchange_opts  = pipeline.amqp[:exchange_opts]  || @exchange_options

          {:ok, %{queue: _queue}} = Queue.declare(channel, queue_name, queue_opts)

          unless :default == exchange_name do
            :ok = Exchange.declare(channel, exchange_name, :direct, exchange_opts)
            :ok = Queue.bind(channel, queue_name, exchange_name)
          end

          :ok = Basic.qos(channel, prefetch_count: prefetch_count)
          :ok = Confirm.select(channel)

          {:ok, consumer_tag} = Basic.consume(channel, queue_name, self, consume_opts)
          {:ok, channel, consumer_tag}
        end) do
      {:ok, channel, consumer_tag} ->
        {:ok, %{channel: channel, consumer_tag: consumer_tag,
                pipeline: pipeline, pid: self, consumer: consumer}}
      {:error, :disconnected} ->
        {:stop, :disconnected}
    end
  end

  @doc false
  def handle_info(:stop_pipe, _from, %{channel: channel, consumer_tag: consumer_tag}=state) do
    {:ok, ^consumer_tag} = Basic.cancel(channel, consumer_tag)
    receive do
      {:basic_cancel_ok, %{consumer_tag: ^consumer_tag}} ->
        Process.demonitor(state.channel.pid)
        Channel.close(channel)
        {:stop, :normal, :ok, state}
    end
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, state) do
    {:noreply, %{state | consumer_tag: tag}}
  end

  def handle_info({:basic_deliver, payload, _meta}, state) do
    spawn(state.consumer, :consume, [payload])
    {:noreply, state}
  end

  def handle_info({:basic_cancel, _meta}, state) do
    Channel.close(state.channel)
    {:stop, :normal, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, %{channel: %{pid: pid}} = state) do
    Logger.error "Channel down: #{inspect reason}"
    Process.demonitor(pid)

    {:stop, {:shutdown, reason}, state}
  end

  def handle_info(message, state) do
    Logger.warn "Unhandled message: #{inspect message}"
    {:noreply, state}
  end

  def terminate(_reason, state) do
    try do
      Channel.close(state.channel)
    catch
      _, _ -> :ok
    end
  end
end

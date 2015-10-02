defmodule Pipes.Publisher do
  @moduledoc false
  use GenServer
  use AMQP
  require Logger

  alias Pipes.Pipeline

  @reconnect_ms 5_000

  # GenServer callbacks

  def start_link(publisher_pool) do
    GenServer.start_link(__MODULE__, [publisher_pool])
  end

  def init([publisher_pool]) do
    Process.flag(:trap_exit, true)
    send self, :connect
    {:ok, %{status: :disconnected, channel: nil, pool: publisher_pool}}
  end

  def handle_call(:channel, _from, %{status: :connected, channel: channel}=state) do
    {:reply, {:ok, channel}, state}
  end

  def handle_call(:channel, _from, %{status: :disconnected}=state) do
    {:reply, {:error, :disconnected}, state}
  end

  def handle_info(:connect, %{status: :disconnected}=state) do
    case Pipeline.with_connection(state.pool, &Channel.open/1) do
      {:ok, channel} ->
        Process.monitor(channel.pid)
        {:noreply, %{state | channel: channel, status: :connected}}
      _ ->
        Logger.warning "Failed to create a channel, retrying after #{inspect @reconnect_ms}ms..."
        :timer.send_after(@reconnect_ms, :connect)
        {:noreply, %{state | channel: nil, status: :disconnected}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{channel: %{pid: pid}}=state) do
    Process.demonitor(pid)
    :timer.send_after(@reconnect_ms, :connect)
    {:noreply, %{state| status: :disconnected, channel: nil}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    :timer.send_after(@reconnect_ms, :connect)
    {:noreply, %{state| status: :disconnected}}
  end

  def terminate(_reason, %{channel: channel, status: :connected}) do
    try do
      Channel.close(channel)
    catch
      _, _ -> :ok
    end
  end
  def terminate(_reason, _state) do
    :ok
  end
end

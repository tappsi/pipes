defmodule Pipes.Connection do
  @moduledoc false
  use GenServer
  use AMQP
  require Logger

  alias Pipes.Pipeline

  @reconnect_after_ms 5_000

  # GenServer callbacks

  def start_link(queue) do
    GenServer.start_link(__MODULE__, [queue])
  end

  def init([queue]) do
    Process.flag(:trap_exit, true)

    send(self, :connect)
    {:ok, %{queue: queue, status: :disconnected, connection: nil}}
  end

  def handle_call(:connection, _from, %{status: :connected, connection: conn}=state) do
    {:reply, {:ok, conn}, state}
  end

  def handle_call(:connection, _from, %{status: :disconnected}=state) do
    {:reply, {:error, :disconnected}, state}
  end

  def handle_info(:connect, %{queue: %Pipeline{amqp: amqp}}=state) do
    case Connection.open(amqp[:uri]) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:noreply, %{state| status: :connected, connection: conn}}
      {:error, reason} ->
        :timer.send_after(@reconnect_after_ms, :connect)
        Logger.error "Reconnecting after #{inspect @reconnect_after_ms}: #{inspect reason}"
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, %{status: :connected}=state) do
    Logger.error "Lost connection: #{inspect reason}. Trying to reconnect after #{inspect @reconnect_after_ms}ms..."
    :timer.send_after(@reconnect_after_ms, :connect)

    {:noreply, %{state| connection: nil, status: :disconnected}}
  end

  def handle_info({:EXIT, _pid, :shutdown}, %{connection: _conn, queue: _queue, status: :connected}=state) do
    Logger.error "Lost connection. Trying to reconnect after #{inspect @reconnect_after_ms}ms..."
    :timer.send_after(@reconnect_after_ms, :connect)

    {:noreply, %{state| connection: nil, status: :disconnected}}
  end

  def handle_info(message, _from, state) do
    IO.warn "Unhandled message: #{inspect message}"
    {:noreply, state}
  end

  def terminate(_reason, %{connection: conn, status: :connected}) do
    try do
      Connection.close(conn)
    catch
      _, _ -> :ok
    end
  end
  def terminate(_reason, _state) do
    :ok
  end
end

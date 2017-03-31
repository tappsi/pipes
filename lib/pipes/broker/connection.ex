defmodule Pipes.Broker.Connection do
  use GenServer
  use AMQP

  require Logger

  @retry_time 5_000

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts])
  end

  # GenServer callbacks

  def init([opts]) do
    case Map.get(opts[:amqp], :uri) do
      nil ->
        Logger.error("Broker `uri` is not definded, cannot stablish connection!")
        {:stop, :normal}
      uri ->
        {:ok, connect(%{uri: uri, status: :disconnected, conn: nil})}
    end
  end

  def handle_call(:get_connection, _from, %{status: :connected, conn: conn} = state) do
    {:reply, {:ok, conn}, state}
  end
  def handle_call(:get_connection, _from, %{status: :disconnected} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  def handle_info(:reconnect, %{status: :disconnected} = state) do
    {:noreply, connect(state)}
  end

  # Internal functions

  defp connect(state) do
    with {:ok, conn} <- AMQP.Connection.open(state.uri) do
      %{state| status: :connected, conn: conn}
    else
      error ->
        Logger.warn "Broker connection problem: #{inspect error}, retry in #{@retry_time}ms..."
        Process.send_after(self(), :reconnect, @retry_time)
        %{state| status: :disconnected, conn: nil}
    end
  end
end

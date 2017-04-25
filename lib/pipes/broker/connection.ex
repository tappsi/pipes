defmodule Pipes.Broker.Connection do
  use GenServer
  use AMQP

  require Logger

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts])
  end

  # GenServer callbacks

  def init([opts]) do

    with {:ok, uri}  <- get_uri(opts),
         {:ok, conn} <- AMQP.Connection.open(uri) do
      {:ok, %{status: :connected, conn: conn, uri: uri}}
    else
      {:error, :no_uri} ->
        Logger.error("Broker `uri` is not definded, cannot stablish connection!")
        {:stop, :normal}
      _ ->
        raise "Broker connection failed!"
    end
  end

  def handle_call(:get_connection, _from, %{status: :connected, conn: conn} = state) do
    {:reply, {:ok, conn}, state}
  end
  def handle_call(:get_connection, _from, %{status: :disconnected} = state) do
    {:reply, {:error, :disconnected}, state}
  end

 # Internal Functions

  defp get_uri(opts) do
    case Map.get(opts[:amqp], :uri) do
      nil ->
        {:error, :no_uri}
      uri ->
        {:ok, uri}
    end
  end
end

defmodule Pipes.Broker.DummyConnection do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_call(:get_connection, _from, state) do
    {:reply, {:ok, %{conn: self()}}, state}
  end
end

defmodule Pipes.Broker.DummyManager do
  use GenServer

  def publish(_, _, _, _) do
    :ok
  end

  def prepare_producer(_, _) do
    {:ok, %{pid: self()}}
  end

  def prepare_consumer(_, _) do
    {:ok, %{pid: self()}}
  end
end

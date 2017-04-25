defmodule PipesTest do
  use ExUnit.Case
  doctest Pipes

  describe "consumer management" do
    defmodule TestConsumer do
      Application.put_env(:pipes, __MODULE__,
                           [name: "consumer_test",
                            amqp: %{uri: "amqp://localhost", queue: "qtest",
                                    exchange: "etest"}])
      use Pipes.Consumer, otp_app: :pipes
    end

    test "default consume returns :ok" do
      assert {:ok, _pid} = TestConsumer.start_link()
      assert TestConsumer.consume("payload") == :ok
    end
  end

  describe "producer management" do
    defmodule TestProducer do
      Application.put_env(:pipes, __MODULE__,
                           [name: "producer_test",
                            amqp: %{uri: "amqp://localhost",
                                    exchange: "etest"}])
      use Pipes.Producer, otp_app: :pipes
    end


    test "default publish returns :ok" do
      assert {:ok, _pid} = TestProducer.start_link()
      assert :ok = TestProducer.publish("payload")
    end
  end
end

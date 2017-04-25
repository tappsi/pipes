defmodule Pipes.Broker.Manager do
  @moduledoc """
  This module allows to prepare a consumer or producer
  creating the required exchanges/queues. This is a wrapper of
  the API of AMQP.
  """
  use AMQP

  @queue_opts    [durable: true, auto_delete: false]
  @exchange_opts [durable: true, auto_delete: false]
  @consumer_opts [nowait: true, no_ack: true]
  @prefetch_count 100


  @doc """
  Basic message publication from AMQP.
  """
  def publish(channel, exchange, routing_key, payload) do
    Basic.publish(channel, exchange, routing_key, payload)
  end

  @doc """
  This function creates a channel and the specified exchange
  by the config options required by a producer

  The `amqp` parameter is a map defined in the env config  file. 

		config :my_app, MyApp.Consumer,
				...
				amqp: %{exchange: "a_exchange"
						 		uri: "amqp://guest:guest@localhost",
                exchange_opts: [durable: true, auto_delete: true, type: :direct]}}
				...
  """
  def prepare_producer(amqp, conn) do
    {:ok, chann} = Channel.open(conn)
    exchange_opts = amqp[:exchange_opts] || @exchange_opts
    exchange_type = exchange_opts[:type] || :direct
    :ok = Exchange.declare(chann, amqp.exchange, exchange_type, exchange_opts)
    {:ok, chann}
  end

  @doc """
  This function creates a channel and the specified exchange
  by the config options required by a consumer.

  The `amqp` parameter is a map defined in the env config  file. 

		config :my_app, MyApp.Consumer,
				...
				amqp: %{exchange: "a_exchange", queue: "queue_a",
						 		uri: "amqp://guest:guest@localhost",
                queue_opts: [durable: true, auto_delete: true, type: :direct]}}
				...
  """
  def prepare_consumer(amqp, conn) do
    {:ok, channel} = Channel.open(conn)

    {:ok, _} = Queue.declare(channel, amqp.queue, amqp[:queue_opts] || @queue_opts)

    exchange_opts = amqp[:exchange_opts] || @exchange_opts
    exchange_type = exchange_opts[:type] || :direct
    :ok = Exchange.declare(channel, amqp.exchange, exchange_type, exchange_opts)

    :ok = Queue.bind(channel, amqp.queue, amqp.exchange)

    :ok = Basic.qos(channel, prefetch_count: @prefetch_count)
    :ok = Confirm.select(channel)

    {:ok, _} = Basic.consume(channel, amqp.queue, self(), @consumer_opts)

    {:ok, channel}
  end
end

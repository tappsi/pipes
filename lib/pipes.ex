defmodule Pipes do
  @moduledoc ~S"""
  Pooled AMQP consumers and publishers

  The `Pipes` application provides the means for creating and
  supervising pipelines of pooled AMQP consumers and publishers.

  It was born out of the Tappsi experience with dealing with RabbitMQ.

  ## Overview

  Each `%Pipe.Pipeline{}` is a collection of RabbitMQ configuration
  parameters and metadata associated to that particular exchange in
  order to ease and simplify development of applications that need
  access to pooled connections, consumers and publishers.
  """
  use Application

  @doc "Start the `Pipes` application"
  def start(_type, _args) do
    Pipes.Supervisor.start_link
  end
end

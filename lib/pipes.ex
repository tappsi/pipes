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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer

      @otp_app opts[:otp_app]
      @max_workers opts[:max_workers] || 4

      alias Pipes.Pipeline

      # GenServer callbacks

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init(_args) do
        pipeline_config = get_config(@otp_app) || missing_config(@otp_app)
        pipeline_specs  = %Pipeline{name: pipeline_config.name,
                                    amqp: pipeline_config.amqp}

        send self, :start_pipeline

        {:ok, %{pipeline: nil, consumers: nil, specs: pipeline_specs}}
      end

      def handle_info(:start_pipeline, state) do
        {:ok, pipeline} = Pipeline.start(state.specs)

        consumers =
          1..@max_workers
          |> Enum.each(fn _ ->
            {:ok, pid} = Pipeline.add_pipe(pipeline, __MODULE__)
            Process.monitor(pid)
            pid
          end)

        {:noreply, %{state| pipeline: pipeline, consumers: consumers}}
      end

      def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
        Process.demonitor(ref)
        {:ok, pid} = Pipeline.add_pipe(state.pipeline, __MODULE__)

        Process.monitor(pid)
        {:noreply, state}
      end

      def config, do: get_config(@otp_app)

      def consume(payload), do: :ok

      # Internal functions

      defp get_config(app) do
        Application.get_env(app, __MODULE__)
      end

      defp missing_config(app) do
        raise "missing OTP configuration for: #{app}"
      end

      defoverridable [consume: 1]
    end
  end

  @callback config() :: Keyword.t
  @callback consume(binary) :: any
end

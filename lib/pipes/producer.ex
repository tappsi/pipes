defmodule Pipes.Producer do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts]  do
      use GenServer

      alias Pipes.{Producer, Utils}

      @otp_app opts[:otp_app]
      @module __MODULE__

      # API

      @doc """
      Publish to the broker the given payload using the pool of
      workers.
      """
      def publish(payload) do
        config    = Utils.get_config(@otp_app, @module)
        pool_name = Utils.pool_name(config[:name], :producer)
        Pipes.Producer.Worker.publish(pool_name, payload)
      end

      def start_link do
        GenServer.start_link(@module, [])
      end

      # GenServer callbacks

      def init(_args) do
        config = Utils.get_config(@otp_app, @module)
        {:ok, _} = Producer.Supervisor.start_pool(config)
        {:ok, :no_state}
      end
    end
  end
end

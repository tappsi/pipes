defmodule Pipes.Producer do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts]  do
      use GenServer

      @otp_app opts[:otp_app]
      @module __MODULE__

      alias Pipes.Producer

      # API

      @doc """
      Publish to the broker the given payload using the pool of
      workers.
      """
      def publish(payload) do
        config = Pipes.get_config(@otp_app, @module)
        pool_name = "#{config[:name]}_producer" |> String.to_atom()
        Pipes.Producer.Worker.publish(pool_name, payload)
      end

      def start_link do
        GenServer.start_link(@module, [])
      end

      # GenServer callbacks

      def init(_args) do
        config = Pipes.get_config(@otp_app, @module)
        {:ok, _} = Producer.Supervisor.start_pool(config)
        {:ok, :no_state}
      end
    end
  end
end

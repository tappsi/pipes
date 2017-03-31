defmodule Pipes.Consumer do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer

      @otp_app opts[:otp_app]
      @module __MODULE__

      def consume(payload), do: :ok

      def start_link do
        GenServer.start_link(@module, [])
      end

      def init(_args) do
        config      = Pipes.get_config(@otp_app, @module)
        opts        = [config, @module]
        max_workers = config[:max_workers] || 4

        for _ <- 1..max_workers,
          do: Supervisor.start_child(Consumer.Supervisor, opts)

        {:ok, %{config: config}}
      end

      defoverridable [consume: 1]
    end
  end
end

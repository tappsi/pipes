defmodule Pipes.Utils do
  @moduledoc """
  This module is used to define common tasks
  required by the internal consumer, producer
  and broker definitions.
  """

  @doc """
  Tries to get module configuration for producer
  or consumers, if there is no configuration raises
  an exception.
  """
  def get_config(otp_app, module) do
    Application.get_env(otp_app, module) || missing_config(module)
  end

  @doc "Defines poolboy requirements per pool"
  def config_pool(name, module, size, max_overflow \\ 0) do
    [{:name, {:local, name}},
      {:worker_module, module},
      {:size, size},
      {:max_overflow, max_overflow}]
  end

  @doc "Build the pool name as atom given a string and its type"
  def pool_name(name, type \\ :consumer),
    do: "#{name}_#{type}" |> String.to_atom()

  # Internal functions

  defp missing_config(module) do
    raise "Missing config for #{module}"
  end
end

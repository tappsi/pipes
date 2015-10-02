defmodule Pipes.Pipeline do
  @moduledoc ~S"""
  Pipeline module
  """
  use AMQP

  @pool_size 5
  @resources [:connection, :channel]

  @pipes_sup    Pipes.Supervisor
  @pipeline_sup Pipes.Pipeline.Supervisor

  defstruct name: nil,
            opts: %{},
            amqp: %{}

  @type t :: %__MODULE__{name: String.t,
                         opts: Map.t,
                         amqp: Map.t}

  # API

  @doc "Create and start a new pipeline"
  def start(%__MODULE__{}=pipeline) do
    pipeline_specs = @pipes_sup.specs(@pipeline_sup, pipeline)
    Supervisor.start_child(@pipes_sup, pipeline_specs)
  end

  @doc "Return the pid of a given `pipeline_name`"
  def get(pipeline_name) do
    get_pipeline_pid(pipeline_name)
  end

  @doc "Terminates a `pipeline`"
  def shutdown(pipeline) do
    :ok = Supervisor.terminate_child(@pipes_sup, pipeline)
    :ok = Supervisor.delete_child(@pipes_sup, pipeline)
  end

  @doc "Return a list the names of all the available pipelines"
  def all do
    all_pipelines()
  end

  @doc "Runs the given `fun` inside the `pool`"
  def with_connection(pipeline, fun) when is_function(fun, 1) do
    case get_resource(pipeline, 0, @pool_size, :connection) do
      {:ok, conn} ->
        fun.(conn)
      error ->
        error
    end
  end

  @doc "Publish a given `payload` to a `pool` under the given `exchange`"
  def publish(pipeline, exchange, payload, routing_key \\ "", opts \\ []) do
    pub_pool = pipeline <> "_publishers" |> String.to_atom
    case get_resource(pub_pool, 0, @pool_size, :channel) do
      {:ok, chan} ->
        Basic.publish(chan, exchange, routing_key, payload, opts)
      error ->
        error
    end
  end

  @doc "Adds a new `pipe` to an existing `pipeline`"
  def add_pipe(pipeline, pipe) do
    GenServer.call(pipeline_server(pipeline), {:add_pipe, pipe}, :infinity)
  end

  @doc "Return all available pipes for `pipeline`"
  def all_pipes(pipeline) do
    GenServer.call(pipeline_server(pipeline), :all_pipes)
  end

  # Internal functions

  defp pipeline_server(pipeline) do
    get_pipeline_name(pipeline) <> "_server" |> String.to_atom
  end

  defp get_pipeline_name(pipeline) do
    [{name, _}] = all() |> Enum.filter fn {_, pid} -> pid == pipeline end
    name
  end

  defp get_pipeline_pid(pipeline) do
    [{_, pid}] = all() |> Enum.filter fn {name, _} -> name == pipeline end
    pid
  end

  defp all_pipelines do
    @pipes_sup
    |> Supervisor.which_children
    |> Enum.map fn {name, pid, _, _} -> {name, pid} end
  end

  defp get_resource(pool, retry_count, max_retries, res) when res in @resources do
    case :poolboy.transaction(pool, &GenServer.call(&1, res)) do
      {:error, _reason} when retry_count < max_retries ->
        get_resource(pool, retry_count - 1, max_retries, res)
      {:error, _reason}=error ->
        error
      {:ok, _conn}=response ->
        response
    end
  end
end

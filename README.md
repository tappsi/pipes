Pipes
=====

Pipes is an application for creating pipelines of pooled AMQP
consumers and publishers.

## Online documentation

*Note*: only available if you are logged in the VPN

You can read the online documentation
[here](http://docs.tappsi.office/core/pipes/).

You can also generate your own local copy:

```sh
$ MIX_ENV=docs mix docs
```

## Usage

```elixir
defmodule Playground do
  alias Pipes.Pipeline

  defmodule Consumer do
    def consume(payload) do
      IO.puts "Yay got: #{inspect payload}"
    end
  end

  pipeline_a_specs = %Pipeline{name: "a",
                               amqp: %{uri: "amqp://guest:guest@localhost",
                                       queue: "queue_a",
                                       exchange: "a_exchange"}}

  {:ok, pipeline_a} = Pipeline.start(pipeline_a_specs)
  {:ok, consumer_a} = Pipeline.add_pipe(pipeline_a, Consumer)

  Pipeline.all()
  Pipeline.all_pipes(pipeline_a)

  Pipeline.publish "a", "a_exchange", "test"
end
```

## Contributing

For general guides on contributing to the project please see
[CONTRIBUTING.md](CONTRIBUTING.md)

## License

Copyright (c) 2015 Tappsi S.A.S

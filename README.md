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
# In config/config.exs
config :my_app, MyApp.Consumer,
  %{name: "my_app_pipeline",
    amqp: %{exchange: "a_exchange", queue: "queue_a",
            uri: "amqp://guest:guest@localhost"}}

# In your supervisor
defmodule MyApp.Supervisor do
  use Supervisor

  def init(_args) do
    children = [worker(MyApp.Consumer, [])]
    supervise(children, [strategy: :one_for_one])
  end
end

# In your consumer module
defmodule MyApp.Consumer do
  use Pipes, otp_app: :my_app

  def consume(payload) do
    do_something(payload)
  end
end
```

## Contributing

For general guides on contributing to the project please see
[CONTRIBUTING.md](CONTRIBUTING.md)

## License

Copyright (c) 2015-2016 Tappsi S.A.S

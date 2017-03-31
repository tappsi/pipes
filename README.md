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

In order to implement consumers the following example shows how to implement them.

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
  use Pipes.Consumer, otp_app: :my_app

  def consume(payload) do
    do_something(payload)
  end
end
```

To define producers the requirements are a bit similar to consumers definitions.

```elixir
# In config/config.exs
config :my_app, MyApp.Producer,
  %{name: "my_app_pipeline",
    amqp: %{exchange: "a_exchange"
            uri: "amqp://guest:guest@localhost"}}

# In your supervisor
defmodule MyApp.Supervisor do
  use Supervisor

  def init(_args) do
    children = [worker(MyApp.Producer, [])]
    supervise(children, [strategy: :one_for_one])
  end
end

# In your consumer module
defmodule MyApp.Producer do
  use Pipes.Producer, otp_app: :my_app
end

# From the module you are interested to publish, a function is available to be called.
MyApp.Producer.publish("my_payload")
```

## Contributing

Please take your time to read throught our
[CONTRIBUTING.md](CONTRIBUTING.md) guide for understanding the
development flow and guidelines.

## Issues and discussions

Consider taking a look at the [issue tracker](https://github.com/tappsi/pipes/issues)
if you want to start helping out.

All documentation non strictly related to source code is found in the
[wiki](https://github.com/tappsi/pipes/wiki). Although not explicitly
stated in the [CONTRIBUTING.md](CONTRIBUTING.md) guidelines, the same
principles apply to the wiki.

## License

Copyright (c) 2015-2017 Tappsi S.A.S

This work is free. You can redeistribute it and/or modify it under
the terms of the MIT License. See the [LICENSE](LICENSE) file for more
details.

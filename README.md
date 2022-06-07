# Deprecated in favor of https://github.com/SpiffInc/events

# PolynMigrator

This packages is intended to be used with a codebase that holds the migration and
schema files for your JetStream NATS Server.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `polyn_migrator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:polyn_migrator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/polyn_migrator](https://hexdocs.pm/polyn_migrator).

## Configuration

### Domain

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) specifies that every event "SHOULD be prefixed with a reverse-DNS name." This name should be consistent throughout your organization. You
define that domain like this:

```elixir
config :polyn_migrator, :domain, "app.spiff"
```

### Connection

You will need to provide the connection settings for your NATS connection. This will differ in-between environments.

```elixir
config :polyn_migrator, :nats, %{
  name: :gnat, # (required) the registered named you want to give the Gnat connection
  backoff_period: 4_000, # number of milliseconds to wait between consecutive reconnect attempts (default: 2_000)
  connection_settings: [
    %{host: "10.0.0.100", port: 4222},
    %{host: "10.0.0.101", port: 4222},
  ]
}
```

## Server Migrations

To create a migration you use the mix task `mix polyn.gen.migration <name>`. If you wanted to create a new stream for user messages you could do the following:

```bash
mix polyn.gen.migration create_user_stream
```

This would add a new migration to your codebase at `priv/polyn/migrations/<timestamp>_create_user_stream.exs`. The TIMESTAMP is a unique number that identifies the migration. It is usually the timestamp of when the migration was created. The NAME must also be unique and it quickly identifies what the migration does. Inside the generated file you would see a module like this:

```elixir
defmodule Polyn.Migrations.CreateUserStream do
  import Polyn.Migration

  def change do
  end
end
```

Inside the `change` function you can use the functions available in `Polyn.Migration` to update the NATS server. You can then run `mix polyn.migrate` to apply your changes.

## Generate a Schema

You can generate a new schema for an event with `mix polyn.gen.schema <name>`. The name of the schema is expected to be alphanumeric, lowercase, and dot separated. This will generate a new file in `priv/polyn/schemas/<name>.json` with JSON Schema boilerplate.

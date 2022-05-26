defmodule Mix.Tasks.Polyn.Migrate do
  @moduledoc """
  Use `mix polyn.migrate` to make configuration changes to your NATS server.
  """
  @shortdoc "Runs migrations to make modifications to your NATS Server"

  use Mix.Task
  alias Polyn.Schema

  def run(args) do
    parse_args(args)
    |> Polyn.Migrator.run()
  end

  defp parse_args(args) do
    {options, []} =
      OptionParser.parse!(args, strict: [migrations_dir: :string, schemas_dir: :string])

    %{
      migrations_dir: Keyword.get(options, :migrations_dir, Polyn.Migrator.migrations_dir()),
      schemas_dir: Keyword.get(options, :schemas_dir, Schema.schemas_dir())
    }
  end
end

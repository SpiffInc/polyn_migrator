defmodule Mix.Tasks.Polyn.Migrate do
  @moduledoc """
  Use `mix polyn.migrate` to make configuration changes to your NATS server.
  """
  @shortdoc "Runs migrations to make modifications to your NATS Server"

  use Mix.Task
  alias Polyn.Schema

  def run(args) do
    Polyn.Migrator.run(args)
  end

  defp parse_args(args) do
    {options, []} = OptionParser.parse!(args, strict: [dir: :string])

    %{
      dir: Keyword.get(options, :dir, Schema.migrations_dir())
    }
  end
end

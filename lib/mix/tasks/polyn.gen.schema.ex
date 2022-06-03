defmodule Mix.Tasks.Polyn.Gen.Schema do
  @moduledoc """
  Use `mix polyn.gen.schema <name>` to generate a new schema for an event in your system

  The `<name>` argument should be the dot-separated name of the event.

  The generated schema will be a json file with some boilerplate JSONSchema populated
  """
  @shortdoc "Generates a new schema file"

  use Mix.Task

  def run(args) do
    parse_args(args)
    |> Polyn.SchemaGenerator.run()
  end

  defp parse_args(args) do
    {options, [name]} = OptionParser.parse!(args, strict: [dir: :string])

    %{
      name: name,
      dir: Keyword.get(options, :dir, Polyn.Schema.schemas_dir())
    }
  end
end

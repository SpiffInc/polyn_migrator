defmodule Polyn.Migrator do
  @moduledoc false
  require Logger
  alias Jetstream.API.Stream
  alias Polyn.MigrationStream
  alias Polyn.Migration.Runner
  alias Polyn.Schema
  alias Polyn.SchemaStore
  alias Polyn.SchemaCompatability

  @typedoc """
  * `:migrations_dir` - Location of migration files
  * `:schemas_dir` - Location of schema files
  * `:schema_store_name` - Name of the K/V store where schemas live
  * `:running_migration_id` - The timestamp/id of the migration file being run. Taken from the beginning of the file name
  * `:migration_files` - The file names of migration files
  * `:migration_modules` - A list of tuples with the migration id and module code
  * `:already_run_migrations` - Migrations we've determined have already been executed on the server
  """

  @type t :: %__MODULE__{
          migrations_dir: binary(),
          schemas_dir: binary(),
          schema_store_name: binary(),
          running_migration_id: non_neg_integer() | nil,
          migration_stream_info: Stream.info() | nil,
          migration_files: list(binary()),
          migration_modules: list({integer(), module()}),
          commands: list({integer(), tuple()}),
          already_run_migrations: list(binary())
        }

  # Holds the state of the migration as we move through migration steps
  defstruct [
    :running_migration_id,
    :migration_stream_info,
    :migrations_dir,
    :schemas_dir,
    :schema_store_name,
    migration_files: [],
    migration_modules: [],
    commands: [],
    already_run_migrations: []
  ]

  def new(opts \\ []) do
    opts =
      Enum.into(opts, %{})
      |> Map.put_new(:migrations_dir, migrations_dir())
      |> Map.put_new(:schemas_dir, Schema.schemas_dir())
      |> Map.put_new(:schema_store_name, SchemaStore.store_name())

    struct!(__MODULE__, opts)
  end

  def run(args) do
    new(args)
    |> fetch_migration_stream_info()
    |> create_migration_stream()
    |> create_schema_store()
    |> add_schemas_to_store()
    |> get_migration_files()
    |> compile_migration_files()
    |> get_migration_commands()
    |> execute_commands()
  end

  @doc """
  Path of migration files
  """
  def migrations_dir do
    Path.join(File.cwd!(), "/priv/polyn/migrations")
  end

  defp fetch_migration_stream_info(state) do
    case MigrationStream.info() do
      {:ok, info} -> Map.put(state, :migration_stream_info, info)
      _ -> state
    end
  end

  # We'll keep all migrations on a JetStream Stream so that we can
  # keep them in order and know which ones have run already
  defp create_migration_stream(%{migration_stream_info: nil} = state) do
    case MigrationStream.create() do
      {:error, reason} ->
        raise Polyn.MigrationException, inspect(reason)

      {:ok, info} ->
        Map.put(state, :migration_stream_info, info)
    end
  end

  defp create_migration_stream(state), do: state

  defp create_schema_store(state) do
    SchemaStore.create_store(name: state.schema_store_name)
    state
  end

  defp add_schemas_to_store(state) do
    File.ls!(state.schemas_dir)
    |> Enum.map(fn file_name ->
      type = String.replace(file_name, ".json", "")
      schema = Schema.compile(type, "1.0.1", dataschema_dir: state.schemas_dir)
      old_schema = SchemaStore.get(type, name: state.schema_store_name)
      SchemaCompatability.check!(old_schema, schema)
      SchemaStore.save(type, schema, name: state.schema_store_name)
    end)

    state
  end

  defp get_migration_files(%{migrations_dir: migrations_dir} = state) do
    files =
      case File.ls(migrations_dir) do
        {:ok, []} ->
          Logger.info("No migrations found at #{migrations_dir}")
          []

        {:ok, files} ->
          files
          |> Enum.filter(&is_elixir_script?/1)
          |> Enum.sort_by(&extract_migration_id/1)

        {:error, _reason} ->
          Logger.info("No migrations found at #{migrations_dir}")
          []
      end

    Map.put(state, :migration_files, files)
  end

  defp is_elixir_script?(file_name) do
    String.ends_with?(file_name, ".exs")
  end

  defp extract_migration_id(file_name) do
    [id | _] = String.split(file_name, "_")
    String.to_integer(id)
  end

  defp compile_migration_files(%{migration_files: files, migrations_dir: migrations_dir} = state) do
    modules =
      Enum.map(files, fn file_name ->
        id = extract_migration_id(file_name)
        [{module, _content}] = Code.compile_file(Path.join(migrations_dir, file_name))
        {id, module}
      end)

    Map.put(state, :migration_modules, modules)
  end

  defp get_migration_commands(state) do
    {:ok, pid} = Runner.start_link(state)
    Process.put(:polyn_migration_runner, pid)

    Enum.each(state.migration_modules, fn {id, module} ->
      Runner.update_running_migration_id(pid, id)
      module.change()
    end)

    state = Runner.get_state(pid)
    Runner.stop(pid)

    state
  end

  defp execute_commands(%{commands: commands} = state) do
    # Gather commmands by migration file so they are executed in order
    Enum.group_by(commands, &elem(&1, 0))
    |> Enum.sort_by(fn {key, _val} -> key end)
    |> Enum.each(fn {id, commands} ->
      Enum.each(commands, &Polyn.Migration.Command.execute/1)
      # We only want to put the migration id into the stream once we know
      # it was successfully executed
      MigrationStream.add_migration(id)
    end)

    state
  end
end

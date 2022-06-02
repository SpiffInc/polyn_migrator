defmodule Polyn.Migrator do
  @moduledoc false
  require Logger
  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Schema
  alias Polyn.SchemaStore
  alias Polyn.SchemaCompatability
  alias Polyn.Serializers.JSON
  alias Polyn.Replicas

  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  @typedoc """
  * `:migrations_dir` - Location of migration files
  * `:schemas_dir` - Location of schema files
  * `:schema_store_name` - Name of the K/V store where schemas live
  * `:running_migration_id` - The timestamp/id of the migration file being run. Taken from the beginning of the file name
  * `:running_migration_command_num` - The number of the command being run in the migration module
  * `:already_run_migrations` - Migrations we've determined have already been executed on the server
  * `:production_migrations` - Migrations that have been run on the production server already
  * `:application_migrations` - Migrations that live locally in the codebase
  """

  @type t :: %__MODULE__{
          migrations_dir: binary(),
          schemas_dir: binary(),
          schema_store_name: binary(),
          running_migration_id: non_neg_integer() | nil,
          running_migration_command_num: non_neg_integer() | nil,
          migration_stream_info: Stream.info() | nil,
          already_run_migrations: list(binary()),
          production_migrations: list(binary()),
          application_migrations: list(binary())
        }

  # Holds the state of the migration as we move through migration steps
  defstruct [
    :running_migration_id,
    :running_migration_command_num,
    :migration_stream_info,
    :migrations_dir,
    :schemas_dir,
    :schema_store_name,
    already_run_migrations: [],
    production_migrations: [],
    application_migrations: []
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
  end

  @doc """
  Path of migration files
  """
  def migrations_dir do
    Path.join(File.cwd!(), "/priv/polyn/migrations")
  end

  defp fetch_migration_stream_info(state) do
    case Stream.info(Connection.name(), @migration_stream) do
      {:ok, info} -> Map.put(state, :migration_stream_info, info)
      _ -> state
    end
  end

  # We'll keep all migrations on a JetStream Stream so that we can
  # keep them in order and know which ones have run already
  defp create_migration_stream(%{migration_stream_info: nil} = state) do
    stream =
      struct!(Stream, %{
        name: @migration_stream,
        subjects: [@migration_subject],
        discard: :new,
        num_replicas: Replicas.three_or_less()
      })

    case Stream.create(Connection.name(), stream) do
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
end

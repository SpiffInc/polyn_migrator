defmodule Polyn.Migrator do
  @moduledoc false
  require Logger
  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Schema
  alias Polyn.SchemaStore
  alias Polyn.Serializers.JSON
  alias Polyn.Replicas

  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  @typedoc """
  * `:migrations_dir` - Location of migration files
  * `:running_migration_id` - The timestamp/id of the migration file being run. Taken from the beginning of the file name
  * `:running_migration_command_num` - The number of the command being run in the migration module
  * `:already_run_migrations` - Migrations we've determined have already been executed on the server
  * `:production_migrations` - Migrations that have been run on the production server already
  * `:application_migrations` - Migrations that live locally in the codebase
  """

  @type t :: %__MODULE__{
          migrations_dir: binary(),
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
    already_run_migrations: [],
    production_migrations: [],
    application_migrations: []
  ]

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def run(args) do
    init_state(args)
    |> fetch_migration_stream_info()
    |> create_migration_stream()
  end

  defp init_state(%{dir: dir}) do
    new(migrations_dir: dir)
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
end

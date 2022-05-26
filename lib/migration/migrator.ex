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

  defmodule State do
    # Holds the state of the migration as we move through migration steps
    @moduledoc false

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
  end

  def run(args) do
    init_state(args)
  end

  defp init_state(%{dir: dir}) do
    State.new(migrations_dir: dir)
  end
end

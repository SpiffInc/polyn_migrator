defmodule Polyn.MigrationStream do
  # Manages the stream that tracks which migrations have already been run
  @moduledoc false

  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Replicas

  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  @doc "Create the migration stream"
  @spec create() :: {:ok, Stream.info()}
  def create(opts \\ []) do
    stream =
      struct!(Stream, %{
        name: stream_name(opts),
        subjects: [stream_subject(opts)],
        discard: :new,
        num_replicas: Replicas.three_or_less()
      })

    Stream.create(Connection.name(), stream)
  end

  @doc "Delete the migration stream"
  @spec delete() :: :ok
  def delete(opts \\ []) do
    Stream.delete(Connection.name(), stream_name(opts))
  end

  @doc "Get information about the migration stream"
  @spec info() :: nil | {:ok, Stream.info()}
  def info(opts \\ []) do
    Stream.info(Connection.name(), stream_name(opts))
  end

  @doc "Add an executed migration to the stream"
  @spec add_migration(migration_id :: binary()) :: :ok
  def add_migration(migration_id, opts \\ [])

  def add_migration(migration_id, opts) when is_integer(migration_id) do
    add_migration(Integer.to_string(migration_id), opts)
  end

  def add_migration(migration_id, opts) do
    Gnat.pub(Connection.name(), stream_subject(opts), migration_id)
  end

  @doc """
  Get the last run migration from the stream
  """
  @spec get_last_migration() :: {:ok, Stream.message_response()}
  def get_last_migration(opts \\ []) do
    Stream.get_message(Connection.name(), stream_name(opts), %{
      last_by_subj: stream_subject(opts)
    })
  end

  defp stream_name(opts) do
    Keyword.get(opts, :name, @migration_stream)
  end

  defp stream_subject(opts) do
    Keyword.get(opts, :subject, @migration_subject)
  end
end

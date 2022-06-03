defmodule Polyn.MigrationStream do
  @moduledoc false

  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Replicas

  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  @doc "Create the migration stream"
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

  @doc "Get information about the migration stream"
  def info(opts \\ []) do
    Stream.info(Connection.name(), stream_name(opts))
  end

  defp stream_name(opts) do
    Keyword.get(opts, :name, @migration_stream)
  end

  defp stream_subject(opts) do
    Keyword.get(opts, :subject, @migration_subject)
  end
end

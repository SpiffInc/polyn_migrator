defmodule Polyn.MigratorTest do
  use ExUnit.Case, async: true

  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Migrator
  # alias Polyn.SchemaStore
  import ExUnit.CaptureLog

  @moduletag :tmp_dir

  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  setup do
    on_exit(fn ->
      Stream.delete(Connection.name(), @migration_stream)
    end)
  end

  @tag capture_log: true
  test "creates migration stream if not there", %{tmp_dir: tmp_dir} do
    Stream.delete(Connection.name(), @migration_stream)
    Migrator.run(%{dir: tmp_dir})
    assert {:ok, info} = Stream.info(Connection.name(), @migration_stream)
    assert info.config.name == @migration_stream
  end

  @tag capture_log: true
  test "ignores migration stream if already existing", %{tmp_dir: tmp_dir} do
    {:ok, _stream} =
      Stream.create(Connection.name(), %Stream{
        name: @migration_stream,
        subjects: [@migration_subject]
      })

    Migrator.run(%{dir: tmp_dir})
    assert {:ok, info} = Stream.info(Connection.name(), @migration_stream)
    assert info.config.name == @migration_stream
  end

  # @tag capture_log: true
  # test "adds the polyn migration schemas to the server", %{tmp_dir: tmp_dir} do
  #   Migrator.run(["foo", tmp_dir])
  #   assert %{} = SchemaStore.get("polyn.schema.create.v1")
  #   assert %{} = SchemaStore.get("polyn.stream.create.v1")
  # end

  # test "adds a migration to create a new stream", %{tmp_dir: tmp_dir} do
  #   add_migration_file(tmp_dir, "1234_create_stream.exs", """
  #   defmodule ExampleCreateStream do
  #     import Polyn.Migration

  #     def change do
  #       create_stream(name: "test_stream", subjects: ["test_subject"])
  #     end
  #   end
  #   """)

  #   Migrator.run(["my_auth_token", tmp_dir])

  #   assert {:ok, %{data: data}} = Migrator.get_last_migration()

  #   data = Jason.decode!(data)
  #   assert data["type"] == "com.test.polyn.stream.create.v1"
  #   assert data["data"]["name"] == "test_stream"
  #   assert data["data"]["subjects"] == ["test_subject"]

  #   assert {:ok, info} = Stream.info(Connection.name(), "test_stream")
  #   assert info.config.name == "test_stream"
  #   Stream.delete(Connection.name(), "test_stream")
  # end

  # test "local migrations ignore non .exs files", %{tmp_dir: tmp_dir} do
  #   File.write!(Path.join(tmp_dir, "foo.text"), "foo")
  #   assert Migrator.run(["my_auth_token", tmp_dir]) == :ok
  # end

  # test "local migrations in correct order", %{tmp_dir: tmp_dir} do
  #   add_migration_file(tmp_dir, "222_create_stream.exs", """
  #   defmodule ExampleSecondStream do
  #     import Polyn.Migration

  #     def change do
  #       create_stream(name: "second_stream", subjects: ["second_subject"])
  #     end
  #   end
  #   """)

  #   add_migration_file(tmp_dir, "111_create_other_stream.exs", """
  #   defmodule ExampleFirstStream do
  #     import Polyn.Migration

  #     def change do
  #       create_stream(name: "first_stream", subjects: ["first_subject"])
  #     end
  #   end
  #   """)

  #   Migrator.run(["my_auth_token", tmp_dir])

  #   assert {:ok, %{data: first_migration}} =
  #            Stream.get_message(Connection.name(), @migration_stream, %{
  #              seq: 1
  #            })

  #   assert {:ok, %{data: second_migration}} =
  #            Stream.get_message(Connection.name(), @migration_stream, %{
  #              seq: 2
  #            })

  #   assert Jason.decode!(first_migration)["data"]["name"] == "first_stream"
  #   assert Jason.decode!(second_migration)["data"]["name"] == "second_stream"
  # end

  # test "logs when no local migrations found", %{tmp_dir: tmp_dir} do
  #   assert capture_log(fn ->
  #            Migrator.run(["my_auth_token", tmp_dir])
  #          end) =~ "No migrations found at #{tmp_dir}"
  # end

  defp add_migration_file(dir, file_name, contents) do
    File.write!(Path.join(dir, file_name), contents)
  end
end

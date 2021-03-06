defmodule Polyn.MigratorTest do
  use ExUnit.Case, async: true

  alias Jetstream.API.Stream
  alias Polyn.Connection
  alias Polyn.Migrator
  alias Polyn.SchemaStore
  import ExUnit.CaptureLog

  @moduletag :tmp_dir

  @store_name "POLYN_SCHEMAS_MIGRATOR_TEST"
  @migration_stream "POLYN_MIGRATIONS"
  @migration_subject "POLYN_MIGRATIONS.all"

  setup context do
    on_exit(fn ->
      Stream.delete(Connection.name(), @migration_stream)
      SchemaStore.delete_store(name: @store_name)
    end)

    migrations_dir = Path.join(context.tmp_dir, "migrations")
    schemas_dir = Path.join(context.tmp_dir, "schemas")

    File.mkdir!(migrations_dir)
    File.mkdir!(schemas_dir)

    Map.put(context, :migrations_dir, migrations_dir)
    |> Map.put(:schemas_dir, schemas_dir)
    |> Map.put(:store_name, @store_name)
  end

  @tag capture_log: true
  test "creates migration stream if not there", context do
    Stream.delete(Connection.name(), @migration_stream)
    run(context)
    assert {:ok, info} = Stream.info(Connection.name(), @migration_stream)
    assert info.config.name == @migration_stream
  end

  @tag capture_log: true
  test "ignores migration stream if already existing", context do
    {:ok, _stream} =
      Stream.create(Connection.name(), %Stream{
        name: @migration_stream,
        subjects: [@migration_subject]
      })

    run(context)
    assert {:ok, info} = Stream.info(Connection.name(), @migration_stream)
    assert info.config.name == @migration_stream
  end

  @tag capture_log: true
  test "adds schemas to the store", context do
    add_dataschema(context.schemas_dir, "foo.bar.v1.json", """
    {
      "type": "null"
    }
    """)

    add_dataschema(context.schemas_dir, "foo.bar.v2.json", """
    {
      "type": "string"
    }
    """)

    run(context)

    assert SchemaStore.get("foo.bar.v1", name: @store_name)["properties"]["data"] == %{
             "type" => "null"
           }

    assert SchemaStore.get("foo.bar.v2", name: @store_name)["properties"]["data"] == %{
             "type" => "string"
           }
  end

  @tag capture_log: true
  test "updates schemas in the store", context do
    SchemaStore.create_store(name: @store_name)

    SchemaStore.save(
      "foo.bar.v1",
      Polyn.Schema.compile("foo.bar.v1", "1.0.1", %{
        "type" => "object",
        "properties" => %{
          "name" => %{
            "type" => "string"
          }
        }
      }),
      name: @store_name
    )

    add_dataschema(context.schemas_dir, "foo.bar.v1.json", """
    {
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        },
        "birthday": {
          "type": "date"
        }
      }
    }
    """)

    run(context)

    assert SchemaStore.get("foo.bar.v1", name: @store_name)["properties"]["data"]["properties"][
             "birthday"
           ] == %{
             "type" => "date"
           }
  end

  test "backwards incompatible schema raises", context do
    SchemaStore.create_store(name: @store_name)

    SchemaStore.save(
      "foo.bar.v1",
      Polyn.Schema.compile("foo.bar.v1", "1.0.1", %{
        "type" => "object",
        "properties" => %{
          "name" => %{
            "type" => "string"
          }
        }
      }),
      name: @store_name
    )

    add_dataschema(context.schemas_dir, "foo.bar.v1.json", """
    {
      "type": "object",
      "properties": {
        "name": {
          "type": "integer"
        }
      }
    }
    """)

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        run(context)
      end)

    assert message =~
             Polyn.SchemaCompatability.Types.changed_message(
               "string",
               "integer",
               "/properties/data/properties/name/type"
             )
  end

  test "adds a migration to create a new stream", context do
    add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
    defmodule ExampleCreateStream do
      import Polyn.Migration

      def change do
        create_stream(name: "test_stream", subjects: ["test_subject"])
      end
    end
    """)

    run(context)

    assert {:ok, %{data: data}} = Polyn.MigrationStream.get_last_migration()
    assert data == "1234"

    assert {:ok, info} = Stream.info(Connection.name(), "test_stream")
    assert info.config.name == "test_stream"
    Stream.delete(Connection.name(), "test_stream")
  end

  test "local migrations ignore non .exs files", context do
    File.write!(Path.join(context.migrations_dir, "foo.text"), "foo")
    assert run(context) == :ok
  end

  test "local migrations in correct order", context do
    add_migration_file(context.migrations_dir, "222_create_stream.exs", """
    defmodule ExampleSecondStream do
      import Polyn.Migration

      def change do
        create_stream(name: "second_stream", subjects: ["second_subject"])
      end
    end
    """)

    add_migration_file(context.migrations_dir, "111_create_other_stream.exs", """
    defmodule ExampleFirstStream do
      import Polyn.Migration

      def change do
        create_stream(name: "first_stream", subjects: ["first_subject"])
      end
    end
    """)

    run(context)

    assert {:ok, %{data: first_migration}} =
             Stream.get_message(Connection.name(), @migration_stream, %{
               seq: 1
             })

    assert {:ok, %{data: second_migration}} =
             Stream.get_message(Connection.name(), @migration_stream, %{
               seq: 2
             })

    assert first_migration == "111"
    assert second_migration == "222"
  end

  test "logs when no local migrations found", context do
    assert capture_log(fn ->
             run(context)
           end) =~ "No migrations found at #{context.migrations_dir}"
  end

  defp run(context) do
    Migrator.run(%{
      migrations_dir: context.migrations_dir,
      schemas_dir: context.schemas_dir,
      schema_store_name: context.store_name
    })
  end

  defp add_migration_file(dir, file_name, contents) do
    File.write!(Path.join(dir, file_name), contents)
  end

  defp add_dataschema(dir, schema_name, content) do
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, schema_name), content)
  end
end

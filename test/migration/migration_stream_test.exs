defmodule Polyn.MigrationStreamTest do
  use ExUnit.Case, async: false

  alias Polyn.MigrationStream

  @stream_name "POLYN_MIGRATIONS_TEST"
  @subject_name "POLYN_MIGRATIONS_TEST.all"

  test "create/1 creates the stream" do
    assert {:ok, info} = MigrationStream.create(opts())
    assert info.config.name == @stream_name
    assert info.config.subjects == [@subject_name]
  end

  test "info/1 gets stream info" do
    assert {:ok, create_info} = MigrationStream.create(opts())
    assert {:ok, info} = MigrationStream.info(opts())
    assert create_info == info
  end

  test "add_migration/2 adds a migration id to the stream" do
    assert {:ok, _info} = MigrationStream.create(opts())
    assert :ok = MigrationStream.add_migration("123", opts())

    assert {:ok, %{data: data}} = MigrationStream.get_last_migration(opts())
    assert data == "123"
  end

  test "add_migration/2 adds a migration id integer to the stream" do
    assert {:ok, _info} = MigrationStream.create(opts())
    assert :ok = MigrationStream.add_migration(123, opts())

    assert {:ok, %{data: data}} = MigrationStream.get_last_migration(opts())
    assert data == "123"
  end

  defp opts do
    [name: @stream_name, subject: @subject_name]
  end
end

defmodule Polyn.MigrationStreamTest do
  use ExUnit.Case, async: false

  alias Polyn.MigrationStream

  @stream_name "POLYN_MIGRATIONS_TEST"
  @subject_name "POLYN_MIGRATIONS_TEST.all"

  test "create/1 creates the stream" do
    assert {:ok, info} = MigrationStream.create(name: @stream_name, subject: @subject_name)
    assert info.config.name == @stream_name
    assert info.config.subjects == [@subject_name]
  end

  test "info/1 gets stream info" do
    assert {:ok, create_info} = MigrationStream.create(name: @stream_name, subject: @subject_name)
    assert {:ok, info} = MigrationStream.info(name: @stream_name, subject: @subject_name)
    assert create_info == info
  end
end

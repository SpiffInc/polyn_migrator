defmodule Polyn.SchemaGeneratorTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaGenerator

  @moduletag :tmp_dir

  test "makes directory if not there", %{tmp_dir: tmp_dir} do
    SchemaGenerator.run(%{name: "foo", dir: Path.join(tmp_dir, "schemas")})
    assert File.dir?(Path.join(tmp_dir, "schemas"))
  end

  test "raise if not unique", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "foo.json"), "")

    assert_raise Mix.Error, ~r"Schema can't be created", fn ->
      SchemaGenerator.run(%{name: "foo", dir: tmp_dir})
    end
  end

  test "raise if invalid name", %{tmp_dir: tmp_dir} do
    assert_raise Mix.Error, ~r"Schema can't be created", fn ->
      SchemaGenerator.run(%{name: "foo   bar", dir: tmp_dir})
    end
  end

  test "generates file", %{tmp_dir: tmp_dir} do
    SchemaGenerator.run(%{name: "foo.bar", dir: tmp_dir})
    json = File.read!(Path.join(tmp_dir, "foo.bar.json")) |> Jason.decode!()
    assert json["$id"] == "com:test:foo:bar"
    assert json["$schema"] =~ "draft-07"
    assert json["description"] == "Describe the purpose of this event"
    assert json["type"] == ""
  end
end

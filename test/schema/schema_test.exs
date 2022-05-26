defmodule Polyn.SchemaTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  alias Polyn.Schema

  test "compile/1 creates a compiled user-defined event and data schema", %{tmp_dir: tmp_dir} do
    add_dataschema(tmp_dir, "foo.bar.v1.json", """
    {
      "type": "null"
    }
    """)

    schema = Schema.compile("foo.bar.v1", "1.0.1", dataschema_dir: tmp_dir)
    assert schema["properties"]["data"] == %{"type" => "null"}
  end

  test "compile/1 raises if no schema for event", %{tmp_dir: tmp_dir} do
    assert_raise(
      Polyn.SchemaException,
      "There is no schema for event foo at #{tmp_dir}/foo.json. Every event must have a schema. Please add a schema for event foo at #{tmp_dir}",
      fn ->
        Schema.compile("foo", "1.0.1", dataschema_dir: tmp_dir)
      end
    )
  end

  test "compile/1 removes dataschema id", %{tmp_dir: tmp_dir} do
    add_dataschema(tmp_dir, "foo.bar.v1.json", """
    {
      "$id": "foo:bar:v1",
      "type": "null"
    }
    """)

    schema = Schema.compile("foo.bar.v1", "1.0.1", dataschema_dir: tmp_dir)
    assert schema["properties"]["data"]["$id"] == nil
  end

  defp add_dataschema(dir, schema_name, content) do
    File.mkdir_p!(dir)
    File.write!(Path.join(dir, schema_name), content)
  end
end

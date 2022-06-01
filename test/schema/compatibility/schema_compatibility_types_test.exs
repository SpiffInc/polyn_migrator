defmodule Polyn.SchemaCompatability.TypesTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability.{Types, State}

  describe "incompatible" do
    test "if type changes" do
      old = %{"type" => "string"}
      new = %{"type" => "null"}

      %State{errors: errors} = Types.check!(State.new(old: old, new: new))
      assert [Types.changed_message("string", "null", "/type")] == errors
    end

    test "if adding a new type" do
      old = %{"type" => "string"}
      new = %{"type" => ["string", "integer"]}

      %State{errors: errors} = Types.check!(State.new(old: old, new: new))
      assert [Types.changed_message("string", ["string", "integer"], "/type")] == errors
    end

    test "if multiple type changes" do
      old = %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"},
          "birthday" => %{"type" => "date"}
        }
      }

      new = %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "integer"},
          "birthday" => %{"type" => "datetime"}
        }
      }

      %State{errors: errors} = Types.check!(State.new(old: old, new: new))

      assert [
               Types.changed_message("string", "integer", "/properties/name/type"),
               Types.changed_message(
                 "date",
                 "datetime",
                 "/properties/birthday/type"
               )
             ] == errors
    end
  end
end

defmodule Polyn.SchemaCompatability.TypesTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability.{PropertyNames, State}

  describe "compatible" do
    test "if adding propertyNames to a previously closed schema and old keys match the pattern" do
      old = %{
        "type" => "object",
        "additionalProperties" => false,
        "properties" => %{
          "NAME" => %{"type" => "string"}
        }
      }

      new = %{
        "type" => "object",
        "properties" => %{
          "NAME" => %{"type" => "string"}
        },
        "propertyNames" => %{
          "pattern" => "^[A-Z]*$"
        }
      }

      %State{errors: []} = PropertyNames.check!(State.new(old: old, new: new))
    end
  end

  describe "incompatible" do
    test "if adding propertyNames to a previously open schema" do
      old = %{"type" => "object"}

      new = %{
        "type" => "object",
        "propertyNames" => %{
          "pattern" => "^[A-Z]*$"
        }
      }

      %State{errors: errors} = PropertyNames.check!(State.new(old: old, new: new))
      assert [PropertyNames.previously_open_message("^[A-Z]*$", "/propertyNames")] == errors
    end
  end

  test "if adding propertyNames to a previously closed schema and old keys does not match the pattern" do
    old = %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    new = %{
      "type" => "object",
      "properties" => %{
        "NAME" => %{"type" => "string"}
      },
      "propertyNames" => %{
        "pattern" => "^[A-Z]*$"
      }
    }

    %State{errors: errors} = PropertyNames.check!(State.new(old: old, new: new))

    assert [
             PropertyNames.non_matching_key_message(
               "^[A-Z]*$",
               "name",
               "/propertyNames",
               "/properties"
             )
           ] == errors
  end

  test "if adding an invalid pattern" do
    old = %{"type" => "object", "additionalProperties" => false}

    new = %{
      "type" => "object",
      "propertyNames" => %{
        "pattern" => "["
      }
    }

    %State{errors: errors} = PropertyNames.check!(State.new(old: old, new: new))

    assert [
             PropertyNames.invalid_pattern_message(
               "/propertyNames",
               "[",
               "{'missing terminating ] for character class', 1}"
             )
           ] == errors
  end
end

defmodule Polyn.SchemaCompatability.TypesTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability.{PropertyNames, State}

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
end

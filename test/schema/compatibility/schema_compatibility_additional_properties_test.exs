defmodule Polyn.SchemaCompatability.AdditionalPropertiesTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability.{AdditionalProperties, State}

  describe "compatibile" do
    test "if additionalProperties added as `true`" do
      old = %{"type" => "object"}

      new = %{"type" => "object", "additionalProperties" => true}

      %State{errors: []} = AdditionalProperties.check!(State.new(old: old, new: new))
    end
  end

  describe "incompatible" do
    test "if additionalProperties was `false` and then removed" do
      old = %{"type" => "object", "additionalProperties" => false}

      new = %{"type" => "object"}

      %State{errors: errors} = AdditionalProperties.check!(State.new(old: old, new: new))
      assert [AdditionalProperties.opening_message(false, nil, "/additionalProperties")] == errors
    end

    test "if additionalProperties was `false` and then true" do
      old = %{"type" => "object", "additionalProperties" => false}

      new = %{"type" => "object", "additionalProperties" => true}

      %State{errors: errors} = AdditionalProperties.check!(State.new(old: old, new: new))

      assert [AdditionalProperties.opening_message(false, true, "/additionalProperties")] ==
               errors
    end

    test "if additionalProperties added as false" do
      old = %{
        "type" => "object"
      }

      new = %{
        "type" => "object",
        "additionalProperties" => false
      }

      %State{errors: errors} = AdditionalProperties.check!(State.new(old: old, new: new))
      assert [AdditionalProperties.closing_message(nil, false, "/additionalProperties")] == errors
    end

    test "if additionalProperties were true then changed to false" do
      old = %{
        "type" => "object",
        "additionalProperties" => true
      }

      new = %{
        "type" => "object",
        "additionalProperties" => false
      }

      %State{errors: errors} = AdditionalProperties.check!(State.new(old: old, new: new))

      assert [AdditionalProperties.closing_message(true, false, "/additionalProperties")] ==
               errors
    end

    test "if additionalProperties were typed then removed" do
      old = %{
        "type" => "object",
        "additionalProperties" => %{"type" => "string"}
      }

      new = %{
        "type" => "object",
        "additionalProperties" => false
      }

      %State{errors: errors} = AdditionalProperties.check!(State.new(old: old, new: new))

      assert [
               AdditionalProperties.closing_message(
                 %{"type" => "string"},
                 false,
                 "/additionalProperties"
               )
             ] ==
               errors
    end
  end
end

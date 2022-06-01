defmodule Polyn.SchemaCompatability.RequiredFieldsTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability.{RequiredFields, State}

  describe "compatible" do
    test "if new optional field is added" do
      old = %{
        "type" => "object",
        "required" => ["name"],
        "properties" => %{
          "name" => %{"type" => "string"}
        }
      }

      new = %{
        "type" => "object",
        "required" => ["name"],
        "properties" => %{
          "name" => %{"type" => "string"},
          "birthday" => %{"type" => "date"}
        }
      }

      assert %State{errors: []} = RequiredFields.check!(State.new(old: old, new: new))
    end

    test "if new nested optional field is added that has required" do
      old = %{
        "type" => "object",
        "required" => ["name"],
        "properties" => %{
          "name" => %{"type" => "string"}
        }
      }

      new = %{
        "type" => "object",
        "required" => ["name"],
        "properties" => %{
          "name" => %{"type" => "string"},
          "address" => %{"type" => "object", "required" => ["zip"]}
        }
      }

      assert %State{errors: []} = RequiredFields.check!(State.new(old: old, new: new))
    end

    test "if required field order changes" do
      old = %{"type" => "object", "required" => ["name", "birthday"]}

      new = %{"type" => "object", "required" => ["birthday", "name"]}

      assert %State{errors: []} = RequiredFields.check!(State.new(old: old, new: new))
    end
  end

  describe "incompatible" do
    test "if existing field becomes required" do
      old = %{"type" => "object"}

      new = %{"type" => "object", "required" => ["name"]}

      %State{errors: errors} = RequiredFields.check!(State.new(old: old, new: new))

      assert [RequiredFields.added_message(["name"], "/required")] == errors
    end

    test "if new required field is added" do
      old = %{"type" => "object", "required" => ["name"]}

      new = %{"type" => "object", "required" => ["name", "birthday"]}

      %State{errors: errors} = RequiredFields.check!(State.new(old: old, new: new))

      assert [RequiredFields.added_message(["birthday"], "/required/1")] == errors
    end

    test "if required removed" do
      old = %{"type" => "object", "required" => ["name"]}

      new = %{"type" => "object"}

      %State{errors: errors} = RequiredFields.check!(State.new(old: old, new: new))

      assert [RequiredFields.removed_message(["name"], "/required")] == errors
    end

    test "if required no longer required" do
      old = %{"type" => "object", "required" => ["name", "birthday"]}

      new = %{"type" => "object", "required" => ["name"]}

      %State{errors: errors} = RequiredFields.check!(State.new(old: old, new: new))

      assert [RequiredFields.removed_message(["birthday"], "/required/1")] == errors
    end

    test "if new required field is added nested" do
      old = %{
        "type" => "object",
        "properties" => %{
          "address" => %{
            "type" => "object",
            "required" => ["line_one"]
          }
        }
      }

      new = %{
        "type" => "object",
        "properties" => %{
          "address" => %{
            "type" => "object",
            "required" => ["line_one", "zip"]
          }
        }
      }

      %State{errors: errors} = RequiredFields.check!(State.new(old: old, new: new))

      assert [RequiredFields.added_message(["zip"], "/properties/address/required/1")] == errors
    end
  end
end

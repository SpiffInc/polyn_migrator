defmodule Polyn.SchemaCompatabilityTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability

  test "compatible if no old" do
    new = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    assert :ok = SchemaCompatability.check!(nil, new)
  end

  test "compatible if exact same" do
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
        "name" => %{"type" => "string"}
      }
    }

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if new optional field is added" do
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

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if new nested optional field is added that has required" do
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

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if required field order changes" do
    old = %{"type" => "object", "required" => ["name", "birthday"]}

    new = %{"type" => "object", "required" => ["birthday", "name"]}

    :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if additionalProperties added as `true`" do
    old = %{"type" => "object"}

    new = %{"type" => "object", "additionalProperties" => true}

    :ok = SchemaCompatability.check!(old, new)
  end

  test "incompatible if existing field becomes required" do
    old = %{"type" => "object"}

    new = %{"type" => "object", "required" => ["name"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~ SchemaCompatability.added_required_fields_message(["name"], "/required")
  end

  test "incompatible if new required field is added" do
    old = %{"type" => "object", "required" => ["name"]}

    new = %{"type" => "object", "required" => ["name", "birthday"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.added_required_fields_message(["birthday"], "/required/1")
  end

  test "incompatible if required removed" do
    old = %{"type" => "object", "required" => ["name"]}

    new = %{"type" => "object"}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~ SchemaCompatability.removed_required_fields_message(["name"], "/required")
  end

  test "incompatible if required no longer required" do
    old = %{"type" => "object", "required" => ["name", "birthday"]}

    new = %{"type" => "object", "required" => ["name"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.removed_required_fields_message(["birthday"], "/required/1")
  end

  test "incompatible if new required field is added nested" do
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

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.added_required_fields_message(
               ["zip"],
               "/properties/address/required/1"
             )
  end

  test "incompatible if type changes" do
    old = %{"type" => "string"}
    new = %{"type" => "null"}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~ SchemaCompatability.changed_type_message("string", "null", "/type")
  end

  test "incompatible if adding a new type" do
    old = %{"type" => "string"}
    new = %{"type" => ["string", "integer"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.changed_type_message("string", ["string", "integer"], "/type")
  end

  test "incompatibile if multiple type changes" do
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

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.changed_type_message(
               "string",
               "integer",
               "/properties/name/type"
             )

    assert message =~
             SchemaCompatability.changed_type_message(
               "date",
               "datetime",
               "/properties/birthday/type"
             )
  end

  test "incompatible if additionalProperties was `false` and then removed" do
    old = %{"type" => "object", "additionalProperties" => false}

    new = %{"type" => "object"}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.opening_additional_properties_message(
               false,
               nil,
               "/additionalProperties"
             )
  end

  test "incompatible if additionalProperties was `false` and then true" do
    old = %{"type" => "object", "additionalProperties" => false}

    new = %{"type" => "object", "additionalProperties" => true}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.opening_additional_properties_message(
               false,
               true,
               "/additionalProperties"
             )
  end

  test "incompatible if additionalProperties added as false" do
    old = %{
      "type" => "object"
    }

    new = %{
      "type" => "object",
      "additionalProperties" => false
    }

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             SchemaCompatability.closing_additional_properties_message(
               nil,
               false,
               "/additionalProperties"
             )
  end
end

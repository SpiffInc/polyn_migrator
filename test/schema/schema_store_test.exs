defmodule Polyn.SchemaStoreTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaStore

  @store_name "POLYN_SCHEMAS"

  setup do
    on_exit(fn ->
      SchemaStore.delete_store()
    end)

    :ok
  end

  describe "create_store/0" do
    test "creates a store" do
      assert :ok = SchemaStore.create_store()
    end

    test "called multiple times won't break" do
      assert :ok = SchemaStore.create_store()
      assert :ok = SchemaStore.create_store()
    end

    test "handles when store already exists with different config" do
      Jetstream.API.KV.create_bucket(Polyn.Connection.name(), @store_name, description: "foo")
      assert :ok = SchemaStore.create_store()
    end
  end

  describe "save/2" do
    setup :init_store

    test "persists a new schema" do
      assert :ok =
               SchemaStore.save("foo.bar", %{
                 type: "null"
               })

      assert SchemaStore.get("foo.bar") == %{"type" => "null"}
    end

    test "updates already existing" do
      assert :ok =
               SchemaStore.save("foo.bar", %{
                 type: "string"
               })

      assert :ok =
               SchemaStore.save("foo.bar", %{
                 type: "null"
               })

      assert SchemaStore.get("foo.bar") == %{"type" => "null"}
    end

    test "error if not a JSONSchema document" do
      assert_raise(
        Polyn.SchemaException,
        "Schemas must be valid JSONSchema documents, got %{\"type\" => \"not-a-valid-type\"}",
        fn ->
          SchemaStore.save("foo.bar", %{"type" => "not-a-valid-type"})
        end
      )
    end
  end

  describe "delete/1" do
    setup :init_store

    test "deletes a schema" do
      assert :ok =
               SchemaStore.save("foo.bar", %{
                 type: "null"
               })

      assert :ok = SchemaStore.delete("foo.bar")
      assert SchemaStore.get("foo.bar") == nil
    end

    test "deletes a schema that doesn't exist" do
      assert :ok = SchemaStore.delete("foo.bar")
      assert SchemaStore.get("foo.bar") == nil
    end
  end

  describe "get/1" do
    setup :init_store

    test "returns nil if not found" do
      assert SchemaStore.get("foo.bar") == nil
    end

    test "raises if different kind of error" do
      SchemaStore.delete_store()

      assert_raise(
        Polyn.SchemaException,
        inspect(%{"code" => 404, "description" => "stream not found", "err_code" => 10059}),
        fn ->
          SchemaStore.get("foo.bar")
        end
      )
    end
  end

  defp init_store(context) do
    SchemaStore.create_store()
    context
  end
end

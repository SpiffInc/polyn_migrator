defmodule Polyn.SchemaStore do
  # Persisting and interacting with persisted schemas
  # TODO: Cache all schemas in a genserver (Pull consumer??).
  # optimization could be to look for only the events we want to
  # process. We don't need to do anything when new schemas are added
  # since we expecting the current version of the application's code
  # to be built with only certain schemas in mind
  @moduledoc false

  alias Jetstream.API.KV
  alias Polyn.Connection
  alias Polyn.Replicas

  @store_name "POLYN_SCHEMAS"

  @doc """
  Persist a schema
  """
  @spec save(type :: binary(), schema :: map()) :: :ok
  @spec save(type :: binary(), schema :: map(), opts :: keyword()) :: :ok
  def save(type, schema, opts \\ []) when is_map(schema) do
    is_json_schema?(schema)
    KV.create_key(Connection.name(), store_name(opts), type, encode(schema))
  end

  defp is_json_schema?(schema) do
    ExJsonSchema.Schema.resolve(schema)
  rescue
    ExJsonSchema.Schema.InvalidSchemaError ->
      raise Polyn.SchemaException,
            "Schemas must be valid JSONSchema documents, got #{inspect(schema)}"
  end

  defp encode(schema) do
    case Jason.encode(schema) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise Polyn.SchemaException, inspect(reason)
    end
  end

  @doc """
  Remove a schema
  """
  @spec delete(type :: binary()) :: :ok
  @spec delete(type :: binary(), opts :: keyword()) :: :ok
  def delete(type, opts \\ []) do
    KV.purge_key(Connection.name(), store_name(opts), type)
  end

  @doc """
  Get the schema for an event
  """
  @spec get(type :: binary()) :: nil | map()
  @spec get(type :: binary(), opts :: keyword()) :: nil | map()
  def get(type, opts \\ []) do
    case KV.get_value(Connection.name(), store_name(opts), type) do
      {:error, %{"description" => "no message found"}} -> nil
      {:error, reason} -> raise Polyn.SchemaException, inspect(reason)
      nil -> nil
      schema -> Jason.decode!(schema)
    end
  end

  @doc """
  Create the schema store if it doesn't exist already
  """
  @spec create_store() :: :ok
  @spec create_store(opts :: keyword()) :: :ok
  def create_store(opts \\ []) do
    result =
      KV.create_bucket(Connection.name(), store_name(opts),
        description: "Contains Schemas for all events on the server",
        replicas: Replicas.three_or_less()
      )

    case result do
      {:ok, _info} -> :ok
      # If some other client created the store first, with a slightly different
      # description or config we'll just use the existing one
      {:error, %{"description" => "stream name already in use"}} -> :ok
      {:error, reason} -> raise Polyn.SchemaException, inspect(reason)
    end
  end

  @doc """
  Delete the schema store
  """
  @spec delete_store() :: :ok
  @spec delete_store(opts :: keyword()) :: :ok
  def delete_store(opts \\ []) do
    KV.delete_bucket(Connection.name(), store_name(opts))
  end

  @doc """
  Get a configured store name or the default
  """
  def store_name(opts \\ []) do
    Keyword.get(opts, :name, @store_name)
  end
end

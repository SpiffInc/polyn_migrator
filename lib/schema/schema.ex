defmodule Polyn.Schema do
  @moduledoc false

  alias Polyn.CloudEvent
  alias Polyn.Naming

  @doc """
  Create a combined schema containing both the "event schema"
  and the "dataschema"
  """
  @spec compile(binary(), binary()) :: map()
  @spec compile(binary(), binary(), map()) :: map()
  @spec compile(binary(), binary(), [{:dataschema_dir, binary()}]) :: map()
  def compile(type, specversion, opts \\ [])

  def compile(type, specversion, dataschema) when is_map(dataschema) do
    {_id, dataschema} = Map.pop(dataschema, "$id")
    eventschema = get_eventschema(specversion)

    put_in(eventschema, ["properties", "data"], dataschema)
    |> Map.put("$id", schema_id(type))
  end

  def compile(type, specversion, opts) when is_list(opts) do
    dataschema = get_dataschema(type, opts)
    compile(type, specversion, dataschema)
  end

  defp get_dataschema(type, opts) do
    dir = dataschema_dir(type, Keyword.get(opts, :dataschema_dir))
    path = Path.join(dir, "#{type}.json")

    case File.read(path) do
      {:ok, file} ->
        Jason.decode!(file)

      {:error, _reason} ->
        raise Polyn.SchemaException,
              "There is no schema for event #{type} at #{path}. " <>
                "Every event must have a schema. Please add a schema for event #{type} at #{dir}"
    end
  end

  # If it's an event that Polyn manages (e.g. Migration Events), look in the
  # schema dir within the Polyn package
  defp dataschema_dir("polyn" <> _suffix, _dir), do: migration_schemas_dir()

  # If it's a user-defined event then look in the user's code base for
  # the dataschema dir
  defp dataschema_dir(_event_type, nil), do: schemas_dir()

  # Look in some other schema dir for user-defined events (e.g. in tests)
  defp dataschema_dir(_event_type, dir), do: dir

  defp get_eventschema(version) do
    CloudEvent.json_schema_for_version(version)
  end

  @doc """
  Get the full id of a schema
  """
  def schema_id(type) do
    domain = Application.fetch_env!(:polyn_migrator, :domain)
    "#{Naming.dot_to_colon(domain)}:#{Naming.dot_to_colon(type)}"
  end

  @doc """
  Path of migration schemas that Polyn manages
  """
  def migration_schemas_dir do
    Application.app_dir(:polyn_migrator, ["priv", "migration_schemas"])
  end

  @doc """
  Path of user-defined schemas
  """
  def schemas_dir do
    Path.join(File.cwd!(), "/priv/polyn/schemas")
  end
end

defmodule Polyn.SchemaCompatability.PropertyNames do
  @moduledoc false
  @behaviour Polyn.SchemaCompatability.Checker

  alias Polyn.SchemaCompatability.{State, Utils}

  def check!(%State{} = state) do
    Enum.filter(state.diffs, &changed?/1)
    |> Enum.reduce(state, fn diff, acc ->
      property_names_message(acc, diff)
    end)
  end

  defp changed?(%{"path" => path}) do
    String.contains?(path, "propertyNames")
  end

  defp property_names_message(state, %{"path" => path}) do
    {old, new} = Utils.find_values(state, path, "propertyNames")
    old_additional_properties = find_old_additional_properties(state, path)
    compare_property_names(state, path, old, new, old_additional_properties)
  end

  defp find_old_additional_properties(state, path) do
    path = String.replace(path, "propertyNames", "additionalProperties")
    Utils.find_deepest(path, "additionalProperties", state.old)
  end

  # Previous schema was closed
  defp compare_property_names(state, path, nil, new, false) do
    case Regex.compile(new["pattern"]) do
      {:ok, pattern} ->
        old_keys_match_pattern(state, path, pattern)

      {:error, reason} ->
        State.add_error(state, invalid_pattern_message(path, new["pattern"], inspect(reason)))
    end
  end

  # Previous schema was open
  defp compare_property_names(state, path, nil, new, addl_props)
       when is_nil(addl_props) or addl_props do
    State.add_error(state, previously_open_message(new["pattern"], path))
  end

  defp old_keys_match_pattern(state, path, pattern) do
    properties_path = String.replace(path, "propertyNames", "properties")

    properties = Utils.find_deepest(properties_path, "properties", state.old)

    Enum.reduce(properties, state, fn {key, _value}, acc ->
      if String.match?(key, pattern) do
        acc
      else
        State.add_error(
          acc,
          non_matching_key_message(Regex.source(pattern), key, path, properties_path)
        )
      end
    end)
  end

  def previously_open_message(pattern, path) do
    "You added a propertyNames pattern of #{pattern} at #{path} to a schema that " <>
      "was previously open. This is not backwards-compatible as there may be Producers including " <>
      "additionalProperties in the data that don't conform to the pattern"
  end

  def non_matching_key_message(pattern, key, path, properties_path) do
    "You added a propertyNames pattern of #{pattern} at #{path} to a schema that " <>
      "was previously closed. This could have been backwards-compatible, but the previous schema " <>
      "key of #{key} at #{properties_path} doesn't match the pattern"
  end

  def invalid_pattern_message(path, pattern, reason) do
    "You added a propertyNames pattern of #{pattern} at #{path}. The pattern is not a valid Regex because #{reason}"
  end
end

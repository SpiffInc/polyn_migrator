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

  defp compare_property_names(state, path, nil, new, nil) do
    State.add_error(state, previously_open_message(new["pattern"], path))
  end

  def previously_open_message(pattern, path) do
    "You added a propertyNames pattern of #{pattern} at #{path} to a schema that " <>
      "was previously open. This is not backwards-compatible as there may be additionalProperties " <>
      "included in the data that don't conform to the pattern"
  end
end

defmodule Polyn.SchemaCompatability.AdditionalProperties do
  @moduledoc false
  alias Polyn.SchemaCompatability.{State, Utils}

  @behaviour Polyn.SchemaCompatability.Checker

  def check(state) do
    Enum.filter(state.diffs, &changed?/1)
    |> Enum.reduce(state, fn diff, acc ->
      additional_properties_message(acc, diff)
    end)
  end

  defp changed?(%{"path" => path}) do
    String.contains?(path, "additionalProperties")
  end

  defp additional_properties_message(state, %{"path" => path} = diff) do
    {old, new} = Utils.find_values(state, path, "additionalProperties")

    compare_additional_properties(state, diff, old, new)
  end

  defp compare_additional_properties(state, _diff, nil, true), do: state

  defp compare_additional_properties(state, diff, false, new) do
    State.add_error(state, opening_message(false, new, diff["path"]))
  end

  defp compare_additional_properties(state, diff, old, false) do
    State.add_error(state, closing_message(old, false, diff["path"]))
  end

  @doc """
  Message if the schema is being "opened" for additionalProperties
  """
  def opening_message(old, new, path) do
    "You changed `additionalProperties` from #{inspect(old)} to #{inspect(new)} at #{path}. " <>
      "Allowing additionalProperties after they were not allowed is not backwards-compatibile. " <>
      "It can break Consumers that were expecting only a certain set of properties to exist"
  end

  @doc """
  Message if the schema is being "closed" for additionalProperties
  """
  def closing_message(old, new, path) do
    "You changed `additionalProperties` from #{inspect(old)} to #{inspect(new)} at #{path}. " <>
      "Disallowing additionalProperties after they were allowed is not backwards-compatibile. " <>
      "It can cause existing Producers that were including additional properties in their payload to fail validation"
  end
end

defmodule Polyn.SchemaCompatability.RequiredFields do
  # Compatibility checks for required field changes
  @moduledoc false

  alias Polyn.SchemaCompatability.{State, Utils}

  def check!(state) do
    Enum.filter(state.diffs, &changed?/1)
    |> Enum.reduce(state, fn diff, acc ->
      required_message(acc, diff)
    end)
  end

  defp changed?(%{"path" => path}) do
    String.contains?(path, "required")
  end

  defp required_message(state, %{"path" => path} = diff) do
    {old, new} = Utils.find_values(state, path, "required")

    compare_required(state, diff, old, new)
  end

  defp compare_required(state, diff, nil, new) do
    State.add_error(state, added_message(new, diff["path"]))
  end

  defp compare_required(state, diff, old, nil) do
    State.add_error(state, removed_message(old, diff["path"]))
  end

  defp compare_required(state, diff, old, new) do
    old = MapSet.new(old)
    new = MapSet.new(new)

    if MapSet.equal?(old, new) do
      state
    else
      added_required_values(state, diff, old, new)
      |> removed_required_values(diff, old, new)
    end
  end

  defp added_required_values(state, diff, old_set, new_set) do
    added = MapSet.difference(new_set, old_set) |> Enum.to_list()

    if Enum.empty?(added) do
      state
    else
      State.add_error(state, added_message(added, diff["path"]))
    end
  end

  defp removed_required_values(state, diff, old_set, new_set) do
    removed = MapSet.difference(old_set, new_set) |> Enum.to_list()

    if Enum.empty?(removed) do
      state
    else
      State.add_error(state, removed_message(removed, diff["path"]))
    end
  end

  @doc "Message when required fields are added"
  def added_message(values, path) do
    "You added required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Adding new required fields is not backwards-compatibile. Existing Producers of the " <>
      "event may not be including the new required fields and won't pass validation"
  end

  @doc "Message when required fields are removed"
  def removed_message(values, path) do
    "You removed required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Making fields that were previously required, optional is not backwards-compatibile. " <>
      "Existing Consumers of the event may be expecting the removed required fields to exist " <>
      "and will break when they are not included."
  end
end

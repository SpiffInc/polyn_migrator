defmodule Polyn.SchemaCompatability do
  # A change is backward-compatible if a Consumer of the data
  # doesn't have to change any code to continue consuming the data
  # Also backward-compatible if a Producer can continue producing
  # the data without changing any code (e.g. A migration may run
  # before a Producer codebase is updated and redeployed, we don't
  # want to have to orchestrate deploys to keep things running smoothly)
  @moduledoc false

  defstruct [:old, :new, :diffs, errors: []]

  @doc """
  Check that a new schema is backwards-compatibile with an old schema
  """
  def check!(nil, _new), do: :ok

  def check!(old, new) do
    struct!(__MODULE__, new: new, old: old)
    |> get_diff()
    |> check_differences()
  end

  defp get_diff(%__MODULE__{} = state) do
    Map.put(state, :diffs, JSONDiff.diff(state.old, state.new))
  end

  defp check_differences(%__MODULE__{diffs: []}), do: :ok

  defp check_differences(state) do
    state =
      Enum.reduce(state.diffs, state, fn diff, acc ->
        check_diff(acc, diff)
      end)

    if Enum.empty?(state.errors) do
      :ok
    else
      raise Polyn.SchemaException, Enum.join(state.errors, "\n")
    end
  end

  defp check_diff(state, diff) do
    required_change?(state, diff)
    |> type_change?(diff)
    |> additional_properties_change?(diff)
  end

  defp required_change?(state, %{"path" => path} = diff) do
    if String.contains?(path, "required") do
      required_message(state, diff)
    else
      state
    end
  end

  defp required_message(state, %{"path" => path} = diff) do
    {old, new} = find_values(state, path, "required")

    compare_required(state, diff, old, new)
  end

  defp compare_required(state, diff, nil, new) do
    add_error(state, added_required_fields_message(new, diff["path"]))
  end

  defp compare_required(state, diff, old, nil) do
    add_error(state, removed_required_fields_message(old, diff["path"]))
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
      add_error(state, added_required_fields_message(added, diff["path"]))
    end
  end

  defp removed_required_values(state, diff, old_set, new_set) do
    removed = MapSet.difference(old_set, new_set) |> Enum.to_list()

    if Enum.empty?(removed) do
      state
    else
      add_error(state, removed_required_fields_message(removed, diff["path"]))
    end
  end

  @doc "Message when required fields are added"
  def added_required_fields_message(values, path) do
    "You added required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Adding new required fields is not backwards-compatibile. Existing Producers of the " <>
      "event may not be including the new required fields and won't pass validation"
  end

  @doc "Message when required fields are removed"
  def removed_required_fields_message(values, path) do
    "You removed required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Making fields that were previously required, optional is not backwards-compatibile. " <>
      "Existing Consumers of the event may be expecting the removed required fields to exist " <>
      "and will break when they are not included."
  end

  defp type_change?(state, %{"path" => path} = diff) do
    if String.contains?(path, "type") do
      type_message(state, diff)
    else
      state
    end
  end

  defp type_message(state, %{"path" => path}) do
    {old, new} = find_values(state, path, "type")

    add_error(state, changed_type_message(old, new, path))
  end

  @doc "Message when the type has change"
  def changed_type_message(old, new, path) do
    "You changed the `type` at \"#{path}\" from #{inspect(old)} to #{inspect(new)}. " <>
      "Changing a field's type is not backwards-compatibile. Consumers may be expecting " <>
      "a field to be a specific type and could break if the type is different"
  end

  defp additional_properties_change?(state, %{"path" => path} = diff) do
    if String.contains?(path, "additionalProperties") do
      additional_properties_message(state, diff)
    else
      state
    end
  end

  defp additional_properties_message(state, %{"path" => path} = diff) do
    {old, new} = find_values(state, path, "additionalProperties")

    compare_additional_properties(state, diff, old, new)
  end

  defp compare_additional_properties(state, _diff, nil, true), do: state
  defp compare_additional_properties(state, _diff, false, nil), do: state

  defp find_values(state, path, key) do
    {find_deepest(path, key, state.old), find_deepest(path, key, state.new)}
  end

  defp find_deepest(path, target, json) when is_binary(path) do
    String.split(path, "/")
    |> Enum.map(&path_fragment_to_integer/1)
    |> find_deepest(target, json)
  end

  # Root
  defp find_deepest(["" | tail], target, json) do
    find_deepest(tail, target, json)
  end

  # Not found
  defp find_deepest([], _target, val) do
    val
  end

  defp find_deepest([key | tail], target, json) when is_integer(key) do
    find_deepest(tail, target, Enum.at(json, key))
  end

  defp find_deepest([target | tail], target, json) do
    if Enum.member?(tail, target) do
      find_deepest(tail, target, json)
    else
      json[target]
    end
  end

  defp find_deepest([key | tail], target, json) do
    find_deepest(tail, target, json[key])
  end

  defp path_fragment_to_integer(part) do
    String.to_integer(part)
  rescue
    _ -> part
  end

  defp add_error(state, message) do
    Map.put(state, :errors, Enum.concat(state.errors, [message]))
  end
end
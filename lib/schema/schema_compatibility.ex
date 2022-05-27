defmodule Polyn.SchemaCompatability do
  @moduledoc false

  defstruct [:old, :new, :diffs, errors: []]

  @doc """
  Check that a new schema is backwards-compatibile with a new schema
  """
  def check!(nil, _new), do: :ok

  def check!(old, new) do
    struct!(__MODULE__, new: new, old: old)
    |> get_diff()
    |> tap(fn state -> IO.inspect(state.diffs, label: "DIFFS") end)
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
  end

  defp required_change?(state, %{"path" => path} = diff) do
    if String.contains?(path, "required") do
      required_message(state, diff)
    else
      state
    end
  end

  defp required_message(state, %{"path" => path} = diff) do
    old_value = find_deepest(path, "required", state.old)
    new_value = find_deepest(path, "required", state.new)

    compare_required(state, diff, old_value, new_value)
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

  defp added_required_fields_message(values, path) do
    "You added required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Adding new required fields is not backwards-compatibile"
  end

  defp removed_required_fields_message(values, path) do
    "You removed required fields of #{inspect(values)} at path \"#{path}\". " <>
      "Making fields that were previously required, optional is not backwards-compatibile"
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

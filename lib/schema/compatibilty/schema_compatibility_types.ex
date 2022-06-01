defmodule Polyn.SchemaCompatability.Types do
  @moduledoc false

  alias Polyn.SchemaCompatability.{State, Utils}

  @behaviour Polyn.SchemaCompatability.Checker

  def check(state) do
    Enum.filter(state.diffs, &changed?/1)
    |> Enum.reduce(state, fn diff, acc ->
      type_message(acc, diff)
    end)
  end

  defp changed?(%{"path" => path}) do
    String.contains?(path, "type")
  end

  defp type_message(state, %{"path" => path}) do
    {old, new} = Utils.find_values(state, path, "type")

    State.add_error(state, changed_message(old, new, path))
  end

  @doc "Message when the type has change"
  def changed_message(old, new, path) do
    "You changed the `type` at \"#{path}\" from #{inspect(old)} to #{inspect(new)}. " <>
      "Changing a field's type is not backwards-compatibile. Consumers may be expecting " <>
      "a field to be a specific type and could break if the type is different"
  end
end

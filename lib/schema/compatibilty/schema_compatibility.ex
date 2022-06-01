defmodule Polyn.SchemaCompatability do
  # A change is backward-compatible if a Consumer of the data
  # doesn't have to change any code to continue consuming the data
  # Also backward-compatible if a Producer can continue producing
  # the data without changing any code (e.g. A migration may run
  # before a Producer codebase is updated and redeployed, we don't
  # want to have to orchestrate deploys to keep things running smoothly)
  @moduledoc false

  alias Polyn.SchemaCompatability.{
    AdditionalProperties,
    PropertyNames,
    RequiredFields,
    State,
    Types
  }

  @doc """
  Check that a new schema is backwards-compatibile with an old schema
  """
  @spec check!(map() | nil, map()) :: :ok
  def check!(nil, _new), do: :ok

  def check!(old, new) do
    State.new(new: new, old: old)
    |> check_differences()
  end

  defp check_differences(%State{diffs: []}), do: :ok

  defp check_differences(%State{} = state) do
    state =
      RequiredFields.check(state)
      |> Types.check()
      |> AdditionalProperties.check()
      |> PropertyNames.check()

    if Enum.empty?(state.errors) do
      :ok
    else
      errors = [header_error(state) | state.errors]
      raise Polyn.SchemaException, Enum.join(errors, "\n")
    end
  end

  defp header_error(state) do
    "You have made a backwards-incompatible change on schema #{state.new["$id"]}. If you " <>
      "need to make a backwards-incompatible change you should create a new schema with a new name " <>
      "(usually this means bumping the version number). " <>
      "Producers should continue to publish the old event until you are certain that there are no more " <>
      "Consumers subscribing to it."
  end
end

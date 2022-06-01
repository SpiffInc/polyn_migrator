defmodule Polyn.SchemaCompatability do
  # A change is backward-compatible if a Consumer of the data
  # doesn't have to change any code to continue consuming the data
  # Also backward-compatible if a Producer can continue producing
  # the data without changing any code (e.g. A migration may run
  # before a Producer codebase is updated and redeployed, we don't
  # want to have to orchestrate deploys to keep things running smoothly)
  @moduledoc false

  alias Polyn.SchemaCompatability.{AdditionalProperties, RequiredFields, State, Types}

  @doc """
  Check that a new schema is backwards-compatibile with an old schema
  """
  def check!(nil, _new), do: :ok

  def check!(old, new) do
    State.new(new: new, old: old)
    |> check_differences()
  end

  defp check_differences(%State{diffs: []}), do: :ok

  defp check_differences(%State{} = state) do
    state =
      RequiredFields.check!(state)
      |> Types.check!()
      |> AdditionalProperties.check!()

    if Enum.empty?(state.errors) do
      :ok
    else
      raise Polyn.SchemaException, Enum.join(state.errors, "\n")
    end
  end
end

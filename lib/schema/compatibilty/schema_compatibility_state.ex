defmodule Polyn.SchemaCompatability.State do
  @moduledoc false

  @type t :: %__MODULE__{
          old: map() | nil,
          new: map(),
          diffs: list(map()),
          errors: list(binary())
        }

  defstruct [:old, :new, diffs: [], errors: []]

  def new(fields) do
    struct!(__MODULE__, fields)
    |> add_diffs()
  end

  def add_error(%__MODULE__{} = state, message) do
    Map.put(state, :errors, Enum.concat(state.errors, [message]))
  end

  defp add_diffs(%__MODULE__{} = state) do
    Map.put(state, :diffs, JSONDiff.diff(state.old, state.new))
  end
end

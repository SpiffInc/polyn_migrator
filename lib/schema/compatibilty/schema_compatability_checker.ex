defmodule Polyn.SchemaCompatability.Checker do
  @moduledoc false
  alias Polyn.SchemaCompatability.State

  @callback check!(State.t()) :: State.t()
end

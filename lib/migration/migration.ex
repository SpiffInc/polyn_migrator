defmodule Polyn.Migration do
  @moduledoc """
  Functions for making changes to a NATS server
  """

  alias Polyn.Migration.Runner

  @doc """
  Creates a new Stream for storing message
  """
  @spec create_stream(stream_options :: keyword()) :: :ok
  def create_stream(options) when is_list(options) do
    Enum.into(options, %{})
    |> create_stream()
  end

  @spec create_stream(stream_options :: map()) :: :ok
  def create_stream(opts) when is_map(opts) do
    command = {:create_stream, opts}
    Runner.add_command(runner(), command)
  end

  defp runner do
    Process.get(:polyn_migration_runner)
  end
end

defmodule Polyn.Replicas do
  # Utilities for determining how many replicas to add to vital Streams
  @moduledoc false

  alias Polyn.Connection

  @doc """
  Try and get three replicas if there are at least three servers in the cluster.
  Will do as many servers as there are if less than 3
  """
  def three_or_less do
    info = Gnat.server_info(Connection.name())
    num_servers = Map.get(info, :connect_urls, []) |> Enum.count()

    cond do
      num_servers == 0 -> 1
      num_servers < 3 -> num_servers
      num_servers >= 3 -> 3
    end
  end
end

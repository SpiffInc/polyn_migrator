defmodule PolynMigrator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: PolynMigrator.Worker.start_link(arg)
      # {PolynMigrator.Worker, arg}
      %{
        id: Gnat.ConnectionSupervisor,
        start: {
          Gnat.ConnectionSupervisor,
          :start_link,
          [Application.fetch_env!(:polyn_migrator, :nats), [name: :polyn_connection_supervisor]]
        }
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PolynMigrator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

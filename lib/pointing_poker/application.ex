defmodule PointingPoker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PointingPokerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:pointing_poker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PointingPoker.PubSub},
      {Registry, keys: :unique, name: PointingPoker.Rooms.Registry},
      {DynamicSupervisor, name: PointingPoker.Rooms.RoomSupervisor, strategy: :one_for_one},
      PointingPokerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PointingPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PointingPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

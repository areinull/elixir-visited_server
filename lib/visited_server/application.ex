defmodule VisitedServer.Application do
  @moduledoc false

  use Application

  require RedisPoolex

  def start(_type, _args) do
    children = [
      VisitedServer.Server,
      VisitedServer.Web
    ]

    opts = [strategy: :one_for_one, name: VisitedServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

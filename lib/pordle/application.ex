defmodule Pordle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Pordle.Worker.start_link(arg)
      # {Pordle.Worker, arg}
      {Registry, name: Pordle.GameRegistry, keys: :unique},
      Pordle.GameSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pordle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

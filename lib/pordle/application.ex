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

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end

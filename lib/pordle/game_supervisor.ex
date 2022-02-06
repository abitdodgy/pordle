defmodule Pordle.GameSupervisor do
  @moduledoc """
  Handles the creation of game servers.

  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: opts)
  end

  @doc """
  Creates a new game server with the given options. 


  ## Examples

      iex> GameSupervisor.start_child(opts)
      {:ok, server}

  """
  def start_child(opts) do
    DynamicSupervisor.start_child(__MODULE__, {Pordle.GameServer, opts})
  end
end

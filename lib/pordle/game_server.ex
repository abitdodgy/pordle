defmodule Pordle.GameServer do
  @moduledoc """
  Pordle game server. For game logic, see `Pordle.Game`.

  """
  use GenServer, restart: :temporary

  alias Pordle.Game

  @doc """
  Starts a new game server with the given `opts`.

  ## Examples

      iex> {:ok, pid} = GameServer.start_link(game)
      {:ok, pid}

  """
  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.name))
  end

  @impl true
  def init(game), do: {:ok, game}

  @impl true
  def handle_call({:put_player_move, word}, _from, state) do
    case Game.put_player_move(state, word) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call({:get_game}, _from, state) do
    {:reply, state, state}
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end
end

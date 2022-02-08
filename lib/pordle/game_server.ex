defmodule Pordle.GameServer do
  @moduledoc """
  Pordle game server.

  """
  use GenServer, restart: :temporary

  alias Pordle.Game

  @doc """
  Starts a new game server for the given `game`.

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
      {:error, error} ->
        {:reply, {:error, error}, state}

      new_state ->
        {:reply, new_state, new_state}
    end
  end

  @impl true
  def handle_call({:get_chars_used}, _from, state) do
    result = Game.get_chars_used(state)
    {:reply, result, state}
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end
end

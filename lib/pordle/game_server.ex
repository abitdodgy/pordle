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
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}
    end
  end

  @impl true
  def handle_call({:get_chars_used}, _from, state) do
    result = Game.get_chars_used(state)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_board}, _from, state) do
    result = Game.get_board(state)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_result}, _from, state) do
    result = Game.get_result(state)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_game}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:game_over}, _from, state) do
    {:reply, Game.over?(state), state}
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end
end

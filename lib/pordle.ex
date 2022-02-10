defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  This module contains the public API for interacting with game.

  """
  alias Pordle.{GameSupervisor, Game}

  @doc """
  Creates a new game server with the given options. See `Pordle.Game` for available options.

  ## Examples

      iex> {:ok, pid} = Pordle.create_game()
      {:ok, pid}

      iex> {:ok, pid} = Pordle.create_game(opts)
      {:ok, pid}

  """
  def create_game(opts \\ []) do
    opts
    |> Game.new()
    |> GameSupervisor.start_child()
  end

  @doc """
  Puts the player move onto the board for the given `server`. See `Pordle.put_player_move/2`.

  ## Examples

      iex> Pordle.put_player_move(server, word)
      {:ok, pid}

  """
  def put_player_move(server, word) do
    GenServer.call(server, {:put_player_move, word})
  end

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_game(server)
      %Game{}

  """
  def get_game(server), do: GenServer.call(server, {:get_game})
end

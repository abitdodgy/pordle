defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  """
  alias Pordle.GameSupervisor

  @doc """
  Creates a new supervised game server with the given options.

  A puzzle is automatically generated unless a custom one is provided.
  Note that custom puzzles are not checked against the dictionary, while player moves are.

  When a custom puzzle is provided, `puzzle_size` derived from the given `puzzle`.

  Set the number of moves (guesses) a player can make with the `moves_allowed` option.

  ## Examples

      iex> Pordle.create_game()
      {:ok, pid}

      iex> Pordle.create_game(puzzle_size: 6, moves_allowed: 5)
      {:ok, pid}

  ## Options

      - `puzzle` The puzzle to solve. If absent, the game generates a puzzle with the default `puzzle_size`.
      - `puzzle_size` The length of the puzzle. This option is ignored if a custom puzzle is provided. Defaults to `5`.
      - `moves_allowed` The maximum number of guesses the player can make before the game finishes. Defaults to `6`.

  """
  def create_game(opts \\ []) do
    GameSupervisor.start_child(opts)
  end
end

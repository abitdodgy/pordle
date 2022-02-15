defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  """
  alias Pordle.GameSupervisor

  @doc """
  Creates a new supervised game server with the given options.

  Generates a game `name` unless one is provided.

  A puzzle is automatically generated unless a custom one is provided.
  Note that custom puzzles are not checked against the dictionary, while player moves are.

  When a custom puzzle is provided, the `puzzle_size` option is ignored and derived from the given `puzzle` instead.

  Set the number of moves (guesses) a player can make with the `moves_allowed` option.

  ## Examples

      iex> Pordle.create_game()
      {:ok, pid}

      iex> Pordle.create_game(name: "game", puzzle: "crate")
      {:ok, pid}

      iex> Pordle.create_game(puzzle_size: 6, moves_allowed: 5)
      {:ok, pid}

  ## Options

    - `name` A game identifier that is stored in the Registry. Defaults to `puid/1`
    - `puzzle` A puzzle to solve. If absent, the game generates a puzzle with the default `puzzle_size`.
    - `puzzle_size` The length of the puzzle. This option is ignored if a custom puzzle is provided. Defaults to `5`.
    - `moves_allowed` The maximum number of guesses the player can make before the game ends. Defaults to `6`.

  """
  def create_game(opts \\ []) do
    opts
    |> Keyword.put_new(:name, puid())
    |> GameSupervisor.start_child()
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end

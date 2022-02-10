defmodule Pordle do
  @moduledoc """
  Pordle is a word game based on Wordle, a game built by Josh Wardle.

  This module contains the public API for interacting with game.

  """
  alias Pordle.{GameSupervisor, Game, Dictionary}

  @doc """
  Creates a new game server with the given options.

  Pordle generates a puzzle with the default puzzle size unless a custom puzzle is provided.
  Note that custom puzzles are not checked against the dictionary, while player moves are.

  When a custom puzzle is provided, `puzzle_size` derived from the given `puzzle`.

  Set the number of moves (guesses) a player can make with the `moves_allowed` option.

  ## Examples

      iex> Pordle.create_game()
      %Game{name: "OpMIz...", puzzle_size: 5, moves_allowed: 6, puzzle: ["S", "M", "A", "R", "T"]}

      iex> Pordle.create_game(puzzle_size: 6, moves_allowed: 5)
      %Game{name: "OpMIz...", puzzle_size: 6, moves_allowed: 5, puzzle: ["S", "T", "R", "E", "E", "T"]}

      iex> Pordle.create_game(puzzle: "hear")
      %Game{name: "OpMIz...", puzzle_size: 4, moves_allowed: 6, puzzle: ["H", "E", "A", "R"]}

  ## Game Options

      - `puzzle` The puzzle to solve. If absent, the game generates a puzzle with the default `puzzle_size`.
      - `puzzle_size` The size of the puzzle. This option is ignored if a custom puzzle is provided. Defaults to `5`.
      - `moves_allowed` The number of guesses the player is allowed to make during the game. Defaults to `6`.

  """
  def create_game(opts \\ []) do
    opts
    |> init_puzzle()
    |> init_game_name()
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
    cond do
      valid_word?(word) ->
        GenServer.call(server, {:put_player_move, sanitize_string(word)})

      true ->
        {:error, :word_not_found}
    end
  end

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_game(server)
      %Game{}

  """
  def get_game(server), do: GenServer.call(server, {:get_game})

  defp init_puzzle(opts) do
    puzzle =
      case Keyword.get(opts, :puzzle) do
        nil ->
          opts
          |> Keyword.get_lazy(:puzzle_size, fn ->
            Map.get(Game.__struct__(), :puzzle_size)
          end)
          |> Dictionary.get()
          |> sanitize_string()

        puzzle ->
          sanitize_string(puzzle)
      end

    opts
    |> Keyword.put(:puzzle, puzzle)
    |> Keyword.put(:puzzle_size, String.length(puzzle))
  end

  defp init_game_name(opts), do: Keyword.put_new_lazy(opts, :name, &puid/0)

  defp valid_word?(word) do
    word
    |> String.downcase()
    |> String.trim()
    |> Pordle.Dictionary.valid_entry?()
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp sanitize_string(string) do
    string
    |> String.downcase()
    |> String.trim()
  end
end

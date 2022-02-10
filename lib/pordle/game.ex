defmodule Pordle.Game do
  @moduledoc """
  This module contains logic to create and interact with a Pordle game.

  """
  alias Pordle.Game

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          player: String.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won,
          board: list()
        }

  defstruct name: nil,
            board: nil,
            player: nil,
            puzzle: nil,
            result: nil,
            puzzle_size: 5,
            moves_allowed: 6,
            moves_made: 0

  @doc """
  Initializes a new game struct.

  Unless provided, Pordle generates a puzzle with the default puzzle size. The puzzle size can be customised
  with the `puzzle_size` option. A custom puzzle is not checked against the dictionary.

  When a custom puzzle is provided, the `puzzle_size` option is ignored since its value will be derived
  from the given puzzle.

  The number of guesses a player can make can be configured with the `moves_allowed` option.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", puzzle_size: 5, moves_allowed: 6}

      iex> Game.new(puzzle_size: 6)
      %Game{name: "OpMIz...", puzzle_size: 6}

      iex> Game.new(puzzle: "6")
      %Game{name: "OpMIz...", puzzle_size: 6}

  ## Game Options

      - `puzzle` The puzzle to solve. If absent, the game generates a puzzle with the default `puzzle_size`.
      - `puzzle_size` The size of the puzzle. This option is ignored if a custom puzzle is provided. Defaults to `5`.
      - `moves_allowed` The number of guesses the player is allowed to make during the game. Defaults to `6`.

  """
  def new(opts \\ []) do
    opts =
      opts
      |> put_name()
      |> put_puzzle_and_size()
      |> put_player()

    __MODULE__
    |> struct!(opts)
    |> put_board()
  end

  @doc """
  Validates and adds the player move to the given game.

  ## Examples

      iex> put_player_move(game, player_guess)
      {:ok, %Game{}}

      iex> put_player_move(game, player_guess)
      {:error, :invalid_move}

      iex> put_player_move(game, player_guess)
      {:error, :word_not_found}

      iex> put_player_move(game, player_guess)
      {:error, :game_over}

  """
  def put_player_move(game, player_guess) do
    cond do
      over?(game) ->
        {:error, :game_over}

      not valid_move?(game, player_guess) ->
        {:error, :invalid_move}

      not valid_word?(player_guess) ->
        {:error, :word_not_found}

      true ->
        player_guess = normalize_string(player_guess)

        game =
          game
          |> put_move(player_guess)
          |> put_moves_made()
          |> put_result(player_guess)
        
        {:ok, game}
    end
  end

  @doc """
  Returns whether the game is over.

  ## Examples

      iex> over?(game)
      true

  """
  def over?(%Game{result: result}), do: not is_nil(result)

  defp valid_move?(%Game{puzzle: puzzle}, player_guess) do
    length(puzzle) == String.length(player_guess)
  end

  defp valid_word?(player_guess) do
    player_guess
    |> String.downcase()
    |> String.trim()
    |> Pordle.Dictionary.valid_entry?()
  end

  defp put_name(opts), do: Keyword.put_new_lazy(opts, :name, &puid/0)

  defp put_puzzle_and_size(opts) do
    puzzle =
      case Keyword.get(opts, :puzzle) do
        nil ->
          opts
          |> Keyword.get_lazy(:puzzle_size, fn ->
            Map.get(Game.__struct__(), :puzzle_size)
          end)
          |> Pordle.Dictionary.get()
          |> normalize_string()

        puzzle ->
          normalize_string(puzzle)
      end

    opts
    |> Keyword.put(:puzzle, puzzle)
    |> Keyword.put(:puzzle_size, length(puzzle))
  end

  defp put_player(opts), do: Keyword.put_new_lazy(opts, :player, &puid/0)

  defp put_board(
         %Game{moves_allowed: moves_allowed, puzzle_size: puzzle_size, board: board} = game
       ) do
    cond do
      is_nil(board) ->
        size = 1..(moves_allowed * puzzle_size)

        board =
          for(_row <- size, into: [], do: {nil, :empty})
          |> Enum.chunk_every(puzzle_size)

        Map.put(game, :board, board)

      true ->
        game
    end
  end

  defp put_move(%Game{puzzle: puzzle, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(puzzle, player_guess))
    end)
  end

  defp put_moves_made(game), do: Map.update!(game, :moves_made, &(&1 + 1))

  defp put_result(%Game{board: board, puzzle: puzzle} = game, player_guess) do
    Map.update!(game, :result, fn result ->
      cond do
        puzzle == player_guess ->
          :won

        board_full?(board) ->
          :lost

        true ->
          result
      end
    end)
  end

  defp board_full?(board) do
    not (board
         |> List.flatten()
         |> Enum.any?(fn {char, _type} ->
           is_nil(char)
         end))
  end

  defp parse_move(puzzle, answer) do
    Enum.with_index(answer, fn char, index ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle and count_in_rest(answer, char, index) > count_in(puzzle, char) ->
          {char, :miss}

        char in puzzle ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
    end)
  end

  defp count_in_rest(answer, char, index) do
    answer
    |> Enum.slice(index..-1)
    |> count_in(char)
  end

  defp count_in(list, char), do: Enum.count(list, &(&1 == char))

  defp normalize_string(string) do
    string
    |> String.downcase()
    |> String.trim()
    |> String.codepoints()
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end

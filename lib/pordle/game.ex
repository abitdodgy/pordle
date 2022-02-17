defmodule Pordle.Game do
  @moduledoc """
  Pordle game server. For game logic, see `Pordle.Game`.

  """
  alias Pordle.Game

  @enforce_keys [:name, :puzzle]

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves: list(String.t()) | [],
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won,
          board: list(),
          keys: list()
        }

  defstruct name: nil,
            puzzle: nil,
            result: nil,
            puzzle_size: 5,
            moves: [],
            moves_allowed: 6,
            moves_made: 0,
            board: [],
            keys: []

  @doc """
  Returns a new game struct with the given values. Generates a `board` if one isn't passed in.

  ## Examples

      iex> new([puzzle: "crate", puzzle_size: 5, ...])
      %Game{puzzle: "crate", puzzle_size: 5, ...}

  """
  def new(opts) do
    __MODULE__
    |> struct!(opts)
    |> init_puzzle_size()
    |> init_board()
  end

  @doc """
  Adds the given `move` to the given game's `board` and updates the `moves_made` counter and `result`.

  ## Examples

      iex> play_move(%Game{board: [{nil, :empty}, ...], moves_made: 1}, "crate")
      %Game{board: [{"c", :hit}, ...], moves_made: 2}

  """
  def play_move(game, move) do
    case validate_move(game, move) do
      {:ok, move} ->
        game =
          game
          |> put_moves(move)
          |> put_board(move)
          |> put_result(move)
          |> put_keyboard()

        {:ok, game}

      error ->
        error
    end
  end

  @doc """
  Returns whether the game is finished. The game is considered finished if `result` is not `nil`.

  ## Examples

      iex> finished?(%Game{result: :won})
      true

      iex> finished?(%Game{result: nil})
      false

  """
  def finished?(%Game{result: result}), do: not is_nil(result)

  defp init_puzzle_size(%Game{puzzle: puzzle} = game) do
    Map.put(game, :puzzle_size, String.length(puzzle))
  end

  defp init_board(
         %Game{board: board, puzzle_size: puzzle_size, moves_allowed: moves_allowed} = game
       ) do
    if Enum.empty?(board) do
      size = 1..(moves_allowed * puzzle_size)

      for(_row <- size, into: [], do: {nil, :empty})
      |> Enum.chunk_every(puzzle_size)
      |> then(fn board ->
        Map.put(game, :board, board)
      end)
    else
      board
    end
  end

  defp validate_move(%Game{puzzle: puzzle}, move) do
    cond do
      String.length(puzzle) == String.length(move) ->
        {:ok, move}

      true ->
        {:error, :invalid_move}
    end
  end

  defp put_moves(game, move) do
    game
    |> Map.update!(:moves, &(&1 ++ [move]))
    |> Map.update!(:moves_made, &(&1 + 1))
  end

  defp put_board(%Game{puzzle: puzzle, moves_made: moves_made} = game, move) do
    parsed_move = parse_move(puzzle, move)

    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made - 1, parsed_move)
    end)
  end

  defp put_result(%Game{board: board, puzzle: puzzle} = game, move) do
    Map.update!(game, :result, fn result ->
      cond do
        puzzle == move ->
          :won

        board_full?(board) ->
          :lost

        true ->
          result
      end
    end)
  end

  defp put_keyboard(game) do
    keys =
      game
      |> Map.get(:board)
      |> List.flatten()
      |> Enum.reject(fn {char, _type} -> is_nil(char) end)
      |> Enum.uniq_by(fn {char, _type} -> char end)

    Map.put(game, :keys, keys)
  end

  defp board_full?(board) do
    not (board
         |> List.flatten()
         |> Enum.any?(fn {char, _type} ->
           is_nil(char)
         end))
  end

  defp parse_move(puzzle, answer) do
    puzzle = to_list(puzzle)
    answer = to_list(answer)

    answer
    |> Enum.with_index()
    |> Enum.reduce([], fn {char, index}, acc ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle and count_found(acc, char) < count_in_puzzle(puzzle, char) ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
      |> then(fn result -> acc ++ [result] end)
    end)
  end

  defp count_found(accumulator, char) do
    Enum.count(answer, fn {i, _type} -> i == char end)
  end

  defp count_in_puzzle(puzzle, char) do
    Enum.count(puzzle, &(&1 == char))
  end

  defp to_list(string), do: String.codepoints(string)
end

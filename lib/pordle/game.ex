defmodule Pordle.Game do
  @moduledoc """
  Contains logic and state for playing a Pordle game.

  """
  alias Pordle.Game

  @enforce_keys [:name, :puzzle]

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          puzzle: String.t(),
          moves: list(String.t()) | [],
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won | nil,
          board: list([{atom(), String.t()}]) | [],
          keyboard: list([{atom(), String.t()}]) | []
        }

  defstruct name: nil,
            puzzle: nil,
            result: nil,
            moves: [],
            moves_allowed: 6,
            moves_made: 0,
            board: [],
            keyboard: []

  @doc """
  Returns a new game struct with the given options. Generates a `board` if one isn't passed in.

  ## Examples

      iex> new(name: "foo", puzzle: "crate", moves_allowed: 6)
      %Game{puzzle: "crate", puzzle_size: 5, ...}

  """
  def new(opts) do
    Game
    |> struct(opts)
    |> init_board()
  end

  @doc """
  Adds the given `move` to the given game's `board` and updates the `keyboard`, `moves`, `moves_made` counter, and `result`.

  ## Examples

      iex> play_move(%Game{board: [empty: nil], ...], moves: [], moves_made: 1}, "crate")
      {:ok, %Game{board: [{:hit, "c"}, ...], moves: ["crate"], moves_made: 2, keyboard: [{:hit, "c"}, ...], result: nil}}

  """
  def play_move(game, move) do
    case validate_move(game, move) do
      {:ok, move} ->
        game
        |> put_moves(move)
        |> put_board(move)
        |> put_result(move)
        |> put_keyboard()
        |> then(&{:ok, &1})

      error ->
        error
    end
  end

  defp init_board(%Game{board: [], puzzle: puzzle, moves_allowed: moves_allowed} = game) do
    puzzle_size = String.length(puzzle)

    for _row <- 1..(moves_allowed * puzzle_size), into: [] do
      {:empty, nil}
    end
    |> Enum.chunk_every(puzzle_size)
    |> then(&Map.put(game, :board, &1))
  end

  defp init_board(game), do: game

  defp validate_move(%Game{puzzle: puzzle} = game, move) do
    cond do
      String.length(puzzle) != String.length(move) ->
        {:error, :invalid_move}

      finished?(game) ->
        {:error, :game_over}

      true ->
        {:ok, move}
    end
  end

  defp finished?(%Game{result: result}), do: not is_nil(result)

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

  defp put_result(%Game{puzzle: move} = game, move), do: Map.put(game, :result, :won)

  defp put_result(%Game{moves_made: moves, moves_allowed: moves} = game, _),
    do: Map.put(game, :result, :lost)

  defp put_result(game, _), do: game

  defp put_keyboard(game) do
    keyboard =
      game
      |> Map.get(:board)
      |> List.flatten()
      |> Enum.reject(fn {_type, char} -> is_nil(char) end)
      |> Enum.uniq_by(fn {_type, char} -> char end)

    Map.put(game, :keyboard, keyboard)
  end

  defp parse_move(puzzle, answer) do
    puzzle = to_list(puzzle)
    answer = to_list(answer)

    for {char, index} <- Enum.with_index(answer), reduce: [] do
      acc ->
        cond do
          char == Enum.at(puzzle, index) ->
            {:hit, char}

          char in puzzle and count_found(acc, char) < count_in_puzzle(puzzle, char) ->
            {:nearly, char}

          true ->
            {:miss, char}
        end
        |> then(&(acc ++ [&1]))
    end
  end

  defp count_found(list, char) do
    Enum.count(list, fn {_type, i} -> i == char end)
  end

  defp count_in_puzzle(puzzle, char) do
    Enum.count(puzzle, &(&1 == char))
  end

  defp to_list(string), do: String.codepoints(string)
end

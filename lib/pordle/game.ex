defmodule Pordle.Game do
  @moduledoc """
  Contains logic and state for playing a Pordle game.

  """
  import Pordle, only: [config: 1]
  alias Pordle.Game

  @enforce_keys [:name, :puzzle]

  @derive Jason.Encoder

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          puzzle: String.t(),
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won | nil,
          board: list([{atom(), String.t()}]) | [],
          keyboard: Map.t() | %{}
        }

  defstruct name: nil,
            puzzle: nil,
            result: nil,
            moves_allowed: 6,
            moves_made: 0,
            board: [],
            keyboard: %{}

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
  Commits the current `move` to the game's `board` and updates the `keyboard`, `moves_made` counter, and `result`.

  ## Examples

      iex> play_move(%Game{board: [full: "a", full: "t"]], moves_made: 0, puzzle: "at"})
      {:ok,
       %Game{
         board: [[hit: "a", hit: "t"]],
         keyboard: %{"a" => :hit, "t" => :hit},
         moves_made: 1
       }}


      iex> play_move(%Game{board: [full: "u", full: "t"]], moves_made: 0, puzzle: "at"})
      {:ok,
       %Game{
         board: [[miss: "u", hit: "t"]],
         keyboard: %{"u" => :miss, "t" => :hit},
         moves_made: 1
       }}

  """
  def play_move(%Game{board: board, moves_made: moves_made} = game) do
    move = Enum.at(board, moves_made)

    case validate_move(game, move) do
      :ok ->
        game
        |> put_moves()
        |> put_board(move)
        |> put_result(move)
        |> put_keyboard()
        |> then(&{:ok, &1})

      error ->
        error
    end
  end

  @doc """
  Appends the given char to the first `[empty: nil]` cell on the board.

  ## Examples

      iex> insert_char(%Game{board: [[full: "w", full: "o", full: "r", empty: nil]]}, "d")
      %Game{board: [[full: "w", full: "o", full: "r", full: "d"]]}

  """
  def insert_char(%Game{board: board, moves_made: moves_made} = game, char) do
    row =
      board
      |> Enum.at(moves_made)
      |> List.keyreplace(:empty, 0, {:full, char})

    Map.get_and_update(game, :board, fn board ->
      {:ok, List.replace_at(board, moves_made, row)}
    end)
  end

  @doc """
  Deletes the last char appended to the board.

  ## Examples

      iex> delete_char(%Game{board: [[full: "w", full: "o", full: "r", empty: "d"]]})
      %Game{board: [[full: "w", full: "o", full: "r", empty: nil]]}

  """
  def delete_char(%Game{board: board, moves_made: moves_made} = game) do
    row =
      board
      |> Enum.at(moves_made)
      |> Enum.reverse()
      |> List.keyreplace(:full, 0, {:empty, nil})
      |> Enum.reverse()

    Map.get_and_update(game, :board, fn board ->
      {:ok, List.replace_at(board, moves_made, row)}
    end)
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
    word = to_word(move)

    cond do
      finished?(game) ->
        {:error, :game_over}

      String.length(word) != String.length(puzzle) ->
        {:error, :invalid_move}

      not config(:dictionary).valid?(word) ->
        {:error, :word_not_found}

      true ->
        :ok
    end
  end

  defp finished?(%Game{result: result}), do: not is_nil(result)

  defp put_moves(game) do
    Map.update!(game, :moves_made, &(&1 + 1))
  end

  defp put_board(%Game{puzzle: puzzle, moves_made: moves_made} = game, move) do
    parsed_move = parse_move(puzzle, move)

    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made - 1, parsed_move)
    end)
  end

  defp put_result(
         %Game{puzzle: puzzle, moves_made: moves_made, moves_allowed: moves_allowed} = game,
         move
       ) do
    word = to_word(move)

    cond do
      word == puzzle ->
        Map.put(game, :result, :won)

      moves_made == moves_allowed ->
        Map.put(game, :result, :lost)

      true ->
        game
    end
  end

  defp put_keyboard(game) do
    keyboard =
      game
      |> Map.get(:board)
      |> List.flatten()
      |> Enum.reject(fn {_type, char} -> is_nil(char) end)
      |> Enum.reduce(%{}, fn {type, char}, acc ->
        Map.update(acc, char, type, fn existing_value ->
          if existing_value == :hit, do: existing_value, else: type
        end)
      end)

    Map.put(game, :keyboard, keyboard)
  end

  defp parse_move(puzzle, answer) do
    puzzle = to_list(puzzle)

    for {{_type, char}, index} <- Enum.with_index(answer), reduce: [] do
      acc ->
        cond do
          char == Enum.at(puzzle, index) ->
            acc ++ [hit: char]

          char in puzzle and
              count_found(acc, char) + count_hits_ahead(answer, puzzle, char, index) <
                count_in_puzzle(puzzle, char) ->
            acc ++ [nearly: char]

          true ->
            acc ++ [miss: char]
        end
    end
  end

  defp count_found(list, char) do
    Enum.count(list, fn {_type, i} -> i == char end)
  end

  defp count_hits_ahead(answer, puzzle, char, index) do
    answer_rest = Enum.slice(answer, (index + 1)..-1)
    puzzle_rest = Enum.slice(puzzle, (index + 1)..-1)

    answer_rest
    |> Enum.with_index()
    |> Enum.count(fn {{_type, current}, i} ->
      char == current && current == Enum.at(puzzle_rest, i)
    end)
  end

  defp count_in_puzzle(puzzle, char) do
    Enum.count(puzzle, &(&1 == char))
  end

  defp to_list(string), do: String.codepoints(string)
  defp to_word(list), do: Keyword.values(list) |> Enum.join()
end

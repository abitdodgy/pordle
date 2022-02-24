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
          finished?: Boolean,
          board: list([{atom(), String.t()}]) | [],
          keyboard: Map.t() | %{}
        }

  defstruct name: nil,
            puzzle: nil,
            result: nil,
            finished?: false,
            moves_allowed: 6,
            moves_made: 0,
            board: [],
            keyboard: %{}

  @doc """
  Returns a new game struct with the given options. Generates a `board` if one isn't passed in.

  ## Examples

      iex> new(name: "foo", puzzle: "crate", moves_allowed: 6)
      %Game{name: "foo", puzzle: "crate", moves_allowed: 6, ...}

  """
  def new(opts) do
    Game
    |> struct(opts)
    |> init_board()
  end

  @doc """
  Commits the current `move` to the game's `board` and updates the `keyboard`, `moves_made` counter, `result` and `finished?` keys.

  ## Examples

      iex> play_move(%Game{board: [[full: "a", full: "t"]], moves_made: 0, puzzle: "at"})
      {:ok,
       %Game{
         board: [[hit: "a", hit: "t"]],
         keyboard: %{"a" => :hit, "t" => :hit},
         moves_made: 1,
         result: :won,
         finished?: true
       }}


      iex> play_move(%Game{board: [[full: "u", full: "t"]], moves_made: 0, puzzle: "at"})
      {:ok,
       %Game{
         board: [[miss: "u", hit: "t"]],
         keyboard: %{"u" => :miss, "t" => :hit},
         moves_made: 1,
         result: :lost,
         finished?: true
       }}

  """
  def play_move(%Game{board: board, moves_made: moves_made} = game) do
    current_move = Enum.at(board, moves_made)

    case validate_move(game, current_move) do
      :ok ->
        game
        |> put_board(current_move)
        |> put_keys()
        |> put_moves()
        |> put_result(current_move)
        |> then(fn game -> {:ok, game} end)

      error ->
        error
    end
  end

  @doc """
  Appends the given char to the game `board`.

  ## Examples

      iex> insert_char(%Game{board: [[]]}, "d")
      %Game{board: [[full: "d"]]}

  """
  def insert_char(%Game{board: board, moves_made: moves_made} = game, char) do
    row =
      board
      |> Enum.at(moves_made)
      |> List.keyreplace(:empty, 0, {:full, sanitize(char)})

    Map.get_and_update(game, :board, fn board ->
      {:ok, List.replace_at(board, moves_made, row)}
    end)
  end

  @doc """
  Removes the last char from the game `board`.

  ## Examples

      iex> delete_char(%Game{board: [[full: "f"]]})
      %Game{board: [[]]}

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

  defp validate_move(%Game{finished?: true}, _move), do: {:error, :game_over}

  defp validate_move(%Game{puzzle: puzzle}, move) do
    word = to_word(move)

    cond do
      String.length(word) != String.length(puzzle) ->
        {:error, :invalid_move}

      not config(:dictionary).valid?(word) ->
        {:error, :word_not_found}

      true ->
        :ok
    end
  end

  defp put_board(%Game{puzzle: puzzle, moves_made: moves_made} = game, move) do
    parsed_move = parse_move(puzzle, move)

    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parsed_move)
    end)
  end

  defp put_keys(%Game{board: board, keyboard: keyboard, moves_made: moves_made} = game) do
    current_move = Enum.at(board, moves_made)

    keys =
      Enum.reduce(current_move, keyboard, fn {type, char}, acc ->
        Map.update(acc, char, type, &if(&1 == :hit, do: &1, else: type))
      end)

    Map.put(game, :keyboard, keys)
  end

  defp put_moves(game) do
    Map.update!(game, :moves_made, &(&1 + 1))
  end

  defp put_result(
         %Game{puzzle: puzzle, moves_made: moves_made, moves_allowed: moves_allowed} = game,
         move
       ) do
    word = to_word(move)

    cond do
      word == puzzle ->
        %{game | result: :won, finished?: true}

      moves_made == moves_allowed ->
        %{game | result: :lost, finished?: true}

      true ->
        game
    end
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
      current == char && current == Enum.at(puzzle_rest, i)
    end)
  end

  defp count_in_puzzle(puzzle, char) do
    Enum.count(puzzle, &(&1 == char))
  end

  defp to_list(string), do: String.codepoints(string)

  defp to_word(list) do
    list
    |> Keyword.values()
    |> Enum.join()
  end

  defp sanitize(string) do
    string
    |> String.downcase()
    |> String.trim()
  end
end

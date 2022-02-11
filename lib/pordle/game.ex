defmodule Pordle.Game do
  @moduledoc """
  Pordle game server. For game logic, see `Pordle.Game`.

  """
  use GenServer, restart: :temporary

  alias Pordle.{Game, Dictionary}

  @typedoc """
  A Pordle game type, e.g. `%Game{}`.
  """
  @type t() :: %__MODULE__{
          name: String.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          result: atom() | :lost | :won,
          board: list()
        }

  defstruct name: nil,
            board: nil,
            puzzle: nil,
            result: nil,
            puzzle_size: 5,
            moves_allowed: 6,
            moves_made: 0

  @doc """
  Starts a supervised game server with the given `opts`. Uses `via_tuple` to customise the process registry.

  ## Examples

      iex> {:ok, pid} = GameServer.start_link(opts)
      {:ok, pid}

  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(puid()))
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end

  @doc """
  Returns a new game struct with the given values.

  ## Examples

      iex> new(opts)
      %Game{}

  """
  def new(opts) do
    __MODULE__
    |> struct!(opts)
    |> put_board()
  end

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_game(server)
      %Game{}

  """
  def get_game(server) do
    GenServer.call(server, :get_game)
  end

  @doc """
  Sends the player move for the given `server`.

  ## Examples

      iex> play_move(server, move)
      {:ok, pid}

  """
  def play_move(server, move) do
    word = sanitize(move)

    cond do
      Dictionary.valid_entry?(word) ->
        GenServer.call(server, {:play_move, word})

      true ->
        {:error, :word_not_found}
    end
  end

  @doc """
  Returns whether the game is finished. If the `result` is not `nil`, it's considered finished.

  ## Examples

      iex> finished?(%Game{result: :won})
      true

      iex> finished?(%Game{result: nil})
      false

  """
  def finished?(%Game{result: result}), do: not is_nil(result)

  @impl true
  def init(opts) do
    puzzle = get_puzzle(opts)

    game =
      opts
      |> Keyword.put(:puzzle, puzzle)
      |> Keyword.put(:puzzle_size, String.length(puzzle))
      |> Game.new()

    {:ok, game}
  end

  @impl true
  def handle_call({:play_move, move}, _from, %Game{puzzle: puzzle} = state) do
    if valid_move?(puzzle, move) do
      state
      |> put_move(move)
      |> put_result(move)
      |> then(fn new_state ->
        if finished?(new_state), do: {:stop, :normal, {:ok, new_state}, new_state}, else: {:reply, {:ok, new_state}, new_state}
      end)
    else
      {:reply, {:error, :invalid_move}, state}
    end
  end

  @impl true
  def handle_call(:get_game, _from, state) do
    {:reply, state, state}
  end

  defp get_puzzle(opts) do
    puzzle = Keyword.get(opts, :puzzle)

    if is_nil(puzzle) do
      opts
      |> Keyword.get(:puzzle_size, default_puzzle_size())
      |> Dictionary.get()
    else
      puzzle
    end
    |> sanitize()
  end

  defp put_board(
         %Game{moves_allowed: moves_allowed, puzzle_size: puzzle_size, board: board} = game
       ) do
    cond do
      is_nil(board) ->
        size = 1..(moves_allowed * puzzle_size)

        for(_row <- size, into: [], do: {nil, :empty})
        |> Enum.chunk_every(puzzle_size)
        |> then(fn board -> Map.put(game, :board, board) end)

      true ->
        game
    end
  end

  defp default_puzzle_size, do: Map.get(__MODULE__.__struct__(), :puzzle_size)

  defp valid_move?(puzzle, move) do
    String.length(puzzle) == String.length(move)
  end

  defp put_move(%Game{puzzle: puzzle, moves_made: moves_made} = state, move) do
    parsed_move = parse_move(puzzle, move)

    state
    |> Map.update!(:board, fn board ->
      List.replace_at(board, moves_made, parsed_move)
    end)
    |> Map.update!(:moves_made, &(&1 + 1))
  end

  defp put_result(%Game{board: board, puzzle: puzzle} = state, move) do
    Map.update!(state, :result, fn result ->
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

  defp parse_move(puzzle, answer) do
    puzzle = to_list(puzzle)
    answer = to_list(answer)

    answer
    |> Enum.with_index()
    |> Enum.reduce([], fn {char, index}, acc ->
      cond do
        char == Enum.at(puzzle, index) ->
          {char, :hit}

        char in puzzle and count_in_answer(acc, char) < count_in_puzzle(puzzle, char) ->
          {char, :nearly}

        true ->
          {char, :miss}
      end
      |> then(fn result -> acc ++ [result] end)
    end)
  end

  defp count_in_answer(answer, char) do
    Enum.count(answer, fn {i, _type} -> i == char end)
  end

  defp count_in_puzzle(puzzle, char) do
    Enum.count(puzzle, &(&1 == char))
  end

  defp to_list(string), do: String.codepoints(string)

  defp sanitize(string) do
    string
    |> String.downcase()
    |> String.trim()
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def board_full?(board) do
    not (board
         |> List.flatten()
         |> Enum.any?(fn {char, _type} ->
           is_nil(char)
         end))
  end
end

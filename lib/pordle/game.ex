defmodule Pordle.Game do
  @moduledoc """
  This module contains logic to create and interact with a Pordle game.

  """
  alias Pordle.Game

  defstruct name: nil,
            player: nil,
            puzzle: nil,
            puzzle_size: 5,
            moves_allowed: 6,
            moves_made: 0,
            status: :active,
            board: []

  @enforce_keys [:name, :puzzle, :player]

  @typedoc """
  A Pordle game type.

  """
  @type t() :: %__MODULE__{
          name: String.t(),
          player: Map.t(),
          puzzle: nonempty_charlist(),
          puzzle_size: non_neg_integer() | 5,
          moves_allowed: non_neg_integer() | 6,
          moves_made: non_neg_integer() | 0,
          status: atom() | :active | :lost | :won,
          board: list()
        }

  @doc """
  Initializes a new game struct.

  Pordle automatically generates a puzzle with a default puzzle size. You can customise
  the puzzle size using the `puzzle_size` option.

  If you provide a custom puzzle, the `puzzle_size` option is ignored; its value will be derived from the given puzzle.

  Configure the number of guesses a player can make with the `moves_allowed` option.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", puzzle_size: 5}

      iex> Game.new(puzzle_size: 6)
      %Game{name: "OpMIz...", puzzle_size: 6}

  ## Options

      - `puzzle_size` An `integer` size of the puzzle the game will generate. This option is ignored if a custom puzzle is provided.
      - `puzzle` The puzzle to solve. The game automatically generates one with the default `puzzle_size`.
      - `moves_allowed` The number of guesses the player is allowed to make before the game finishes.

  """
  def new(opts \\ []) do
    opts =
      opts
      |> Keyword.put(:name, puid())
      |> Keyword.put_new_lazy(:puzzle, fn ->
        default_puzzle_size = Map.get(Game.__struct__(), :puzzle_size)

        opts
        |> Keyword.get(:puzzle_size, default_puzzle_size)
        |> Pordle.Dictionary.get()
        |> normalize_string()
      end)

    __MODULE__
    |> struct!(opts)
    |> init_board()
    |> tap(&IO.inspect/1)
  end

  @doc """
  Generates a probably unique string with the given `size`.

  ## Examples

      iex> Game.puid()
      "OpMIz26yIKK5YPN"

      iex> Game.puid(6)
      "sIK9bx"

  """
  def puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Returns a list of chars used by the player.

  ## Examples

      iex> get_chars_used(game)
      [{"a", :hit}, {"s", :nearly}, ...]

  """
  def get_chars_used(%Game{board: board}) do
    board
    |> List.flatten()
    |> Enum.reject(fn {char, _type} -> is_nil(char) end)
    |> Enum.uniq_by(fn {char, _type} -> char end)
  end

  @doc """
  Returns the status of the given `game`.

  ## Examples

      iex> get_status(game)
      {:ok, :won}

  """
  def get_status(%Game{status: status}), do: {:ok, status}

  @doc """
  Returns the game board.

  ## Examples

      iex> get_board(game)
      [{"a", :hit}, {"f", :nearly}, {"c", :miss}, ...]

  """
  def get_board(%Game{board: board}), do: board

  @doc """
  Add the player move to the given game.

  ## Examples

      iex> put_player_move(game, player_guess)
      {:ok, %Game{}}

      iex> put_player_move(game, player_guess)
      {:error, {:game_over, :won}, %Game{}}

  """
  def put_player_move(game, player_guess) do
    unless over?(game) do
      player_guess = normalize_string(player_guess)

      game =
        game
        |> put_board(player_guess)
        |> put_moves_made()
        |> put_status(player_guess)

      {:ok, game}
    else
      {:error, :game_over}
    end
  end

  @doc """
  Returns whether the game is over.

  ## Examples

      iex> over?(game)
      true

  """
  def over?(%Game{status: status}), do: status in [:won, :lost]

  defp put_board(%Game{puzzle: puzzle, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(puzzle, player_guess))
    end)
  end

  defp put_moves_made(game), do: Map.update!(game, :moves_made, &(&1 + 1))

  defp put_status(
         %Game{puzzle: puzzle, moves_made: moves_made, moves_allowed: moves_allowed} = game,
         player_guess
       ) do
    Map.update!(game, :status, fn status ->
      cond do
        puzzle == player_guess ->
          :won

        not (moves_made < moves_allowed) ->
          :lost

        true ->
          status
      end
    end)
  end

  defp init_board(%Game{moves_allowed: moves_allowed, puzzle_size: puzzle_size, board: []} = game) do
    size = 1..(moves_allowed * puzzle_size)

    board =
      for(_row <- size, into: [], do: {nil, :empty})
      |> Enum.chunk_every(puzzle_size)

    Map.put(game, :board, board)
  end

  defp init_board(game), do: game

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
end

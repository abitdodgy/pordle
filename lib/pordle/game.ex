defmodule Pordle.Game do
  @moduledoc """
  A Pordle game.

  """
  alias Pordle.Game

  @enforce_keys [:name, :answer]

  defstruct([
    :name,
    :player,
    :answer,
    word_size: 5,
    moves_allowed: 6,
    moves_made: 0,
    status: :active,
    board: []
  ])

  @doc """
  Initializes a new game struct.

  ## Examples

      iex> Game.new()
      %Game{name: "OpMIz...", word_size: 5}

      iex> Game.new(word_size: 6)
      %Game{name: "OpMIz...", word_size: 6}

  """
  def new(opts \\ []) do
    opts =
      opts
      |> Keyword.put(:name, puid())
      |> Keyword.update!(:answer, &normalize_string/1)

    __MODULE__
    |> struct!(opts)
    |> init_board()
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

  defp put_board(%Game{answer: answer, moves_made: moves_made} = game, player_guess) do
    Map.update!(game, :board, fn board ->
      List.replace_at(board, moves_made, parse_move(answer, player_guess))
    end)
  end

  defp put_moves_made(game), do: Map.update!(game, :moves_made, &(&1 + 1))

  defp put_status(
         %Game{answer: answer, moves_made: moves_made, moves_allowed: moves_allowed} = game,
         player_guess
       ) do
    Map.update!(game, :status, fn status ->
      cond do
        answer == player_guess ->
          :won

        not (moves_made < moves_allowed) ->
          :lost

        true ->
          status
      end
    end)
  end

  defp init_board(%Game{moves_allowed: moves_allowed, word_size: word_size, board: []} = game) do
    size = 1..(moves_allowed * word_size)

    board =
      for(_row <- size, into: [], do: {nil, :empty})
      |> Enum.chunk_every(word_size)

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

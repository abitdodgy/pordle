defmodule Pordle.GameServer do
  @moduledoc """
  Pordle game server. For game logic, see `Pordle.Game`.

  """
  use GenServer, restart: :temporary

  alias Pordle.{Game, Puzzle}

  @doc """
  Starts a supervised game server with the given `opts`. Uses `via_tuple` to customise the process registry.

  ## Examples

      iex> {:ok, pid} = GameServer.start_link(opts)
      {:ok, pid}

  """
  def start_link(opts) do
    {name, opts} =
      Keyword.get_and_update(opts, :name, fn current_name ->
        if is_nil(current_name) do
          {current_name, puid()}
        else
          {current_name, current_name}
        end
      end)

    GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Returns the game struct for the given `server`.

  ## Examples

      iex> get_state(server)
      %Game{}

  """
  def get_state(server) do
    GenServer.call(server, :get_state)
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
      Puzzle.valid?(word) ->
        GenServer.call(server, {:play_move, word})

      true ->
        {:error, :word_not_found}
    end
  end

  @impl true
  def init(opts) do
    puzzle =
      Keyword.get_lazy(opts, :puzzle, fn ->
        opts
        |> Keyword.get(:puzzle_size, Application.fetch_env!(:pordle, :default_puzzle_size))
        |> Puzzle.new()
      end)

    game =
      opts
      |> Keyword.put(:puzzle, puzzle)
      |> Keyword.put(:puzzle_size, String.length(puzzle))
      |> Game.new()

    {:ok, game}
  end

  @impl true
  def handle_call({:play_move, move}, _from, state) do
    case Game.play_move(state, move) do
      {:ok, new_state} ->
        if Game.finished?(new_state) do
          {:stop, :normal, {:ok, new_state}, new_state}
        else
          {:reply, {:ok, new_state}, new_state}
        end

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp sanitize(string) do
    string
    |> String.downcase()
    |> String.trim()
  end
end

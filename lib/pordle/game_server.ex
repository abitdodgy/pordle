defmodule Pordle.GameServer do
  @moduledoc """
  Pordle game server. For game logic, see `Pordle.Game`.

  """
  use GenServer, restart: :temporary

  alias Pordle.Game

  @doc """
  Starts a supervised game server with the given `opts`. Uses `via_tuple` to customise the process registry.

  ## Examples

      iex> start_link(opts)
      {:ok, pid}

  ## Options

  See `Pordle.create_game/1` for a list of options.

  """
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
  end

  defp via_tuple(name) do
    Pordle.GameRegistry.via_tuple({__MODULE__, name})
  end

  @impl true
  def init(opts) do
    opts =
      Keyword.put_new_lazy(opts, :puzzle, fn ->
        opts
        |> Keyword.get(:puzzle_size, Pordle.config(:default_puzzle_size))
        |> Pordle.config(:dictionary).new()
      end)

    {:ok, Game.new(opts)}
  end

  @doc """
  Returns the game struct for the game with the given `name`.

  ## Examples

      iex> get_state(name)
      {:ok, %Game{}}

  """
  def get_state(name) do
    name
    |> via_tuple()
    |> GenServer.call(:get_state)
  end

  @doc """
  Commits the player move to the game with the given `name`.

  ## Examples

      iex> play_move(name)
      {:ok, %Game{}}

  """
  def play_move(name) do
    name
    |> via_tuple()
    |> GenServer.call(:play_move)
  end

  @doc """
  Adds a char to the board of the given game. See `Pordle.Game.insert_char/2` for details.

  ## Examples

      iex> insert_char(game, "x")
      iex> %Game{board: [[full: "x"]]}

  """
  def insert_char(name, char) do
    char = sanitize(char)

    name
    |> via_tuple()
    |> GenServer.call({:insert_char, char})
  end

  @doc """
  Deletes a char from the board of the given game. See `Pordle.Game.delete_char/1` for details.

  ## Examples

      iex> delete_char(game)
      iex> %Game{board: [[empty: nil]]}

  """
  def delete_char(name) do
    name
    |> via_tuple()
    |> GenServer.call(:delete_char)
  end

  @doc """
  Shuts down the server process for the given `name`.

  ## Examples

      iex> exit(name)
      :ok

  """
  def exit(name) do
    name
    |> via_tuple()
    |> GenServer.cast(:exit)
  end

  #               #
  #   Server API  #
  #               #

  @impl true
  def handle_call(:play_move, _from, state) do
    case Game.play_move(state) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:insert_char, char}, _from, state) do
    case Game.insert_char(state, char) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:delete_char, _from, state) do
    case Game.delete_char(state) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(:exit, state) do
    {:stop, :normal, state}
  end

  defp sanitize(string) do
    string
    |> String.downcase()
    |> String.trim()
  end
end

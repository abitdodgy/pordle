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
  Sends the player move to the game with the given `name`.

  ## Examples

      iex> play_move(name, move)
      {:ok, %Game{}}

  """
  def play_move(name, move) do
    word = sanitize(move)

    cond do
      config(:validate_with).(word) ->
        name
        |> via_tuple()
        |> GenServer.call({:play_move, word})

      true ->
        {:error, :word_not_found}
    end
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

  @impl true
  def handle_call({:play_move, move}, _from, state) do
    case Game.play_move(state, move) do
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

  defp config(key) do
    Application.fetch_env!(:pordle, key)
  end
end

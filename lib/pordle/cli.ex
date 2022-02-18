defmodule Pordle.CLI do
  @moduledoc """
  Play Pordle using a Command Line Interface.

  """
  import Pordle.CLI.Narrator, only: [print_line: 1, print_line: 2, print_state: 1, get_line: 1]

  alias Pordle.Game

  @doc """
  Entry point for the game.

  """
  def main(argv) do
    print_line(:game_start)

    server = puid()

    {:ok, _pid} =
      argv
      |> parse_args()
      |> put_puzzle()
      |> Keyword.put_new(:name, server)
      |> Pordle.create_game()

    {:ok, state} = Pordle.get_state(server)

    print_state(state)
    receive_command(server)
  end

  defp parse_args(args) do
    {options, _, _} =
      OptionParser.parse(args,
        switches: [
          puzzle_size: :integer,
          player: :string,
          moves_allowed: :integer,
          puzzle: :string
        ],
        aliases: [s: :puzzle_size, g: :moves_allowed, p: :puzzle]
      )

    options
  end

  defp put_puzzle(opts) do
    puzzle =
      Keyword.get_lazy(opts, :puzzle, fn ->
        opts
        |> Keyword.get(:puzzle_size, config(:default_puzzle_size))
        |> config(:dictionary).new()
      end)

    Keyword.put(opts, :puzzle, puzzle)
  end

  defp receive_command(server) do
    :make_guess
    |> get_line()
    |> IO.gets()
    |> String.trim()
    |> execute_command(server)
  end

  defp execute_command(":quit", server) do
    print_line(:quit)
    shutdown(server)
  end

  defp execute_command(":help", server) do
    print_line(:help)
    receive_command(server)
  end

  defp execute_command(guess, server) do
    play_move(server, guess)
  end

  defp play_move(server, guess) do
    server
    |> Pordle.play_move(guess)
    |> case do
      {:ok, %Game{result: :won, moves_made: moves_made} = game} ->
        print_line(:player_move, move: guess)
        print_state(game)
        print_line(:game_won, moves_made: moves_made)
        shutdown(server)

      {:ok, %Game{result: :lost} = game} ->
        print_line(:player_move, move: guess)
        print_state(game)
        print_line(:game_lost)
        shutdown(server)

      {:ok, state} ->
        print_line(:player_move, move: guess)
        print_state(state)
        receive_command(server)

      {:error, :invalid_move} ->
        print_line(:invalid_move, move: guess)
        receive_command(server)

      {:error, :word_not_found} ->
        print_line(:word_not_found, word: guess)
        receive_command(server)

      {:error, :game_over} ->
        print_line(:game_over)
        shutdown(server)
    end
  end

  defp shutdown(server) do
    Pordle.exit(server)
  end

  defp config(key) do
    Application.fetch_env!(:pordle, key)
  end

  defp puid(size \\ 15) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end

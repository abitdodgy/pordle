defmodule Pordle.CLI.Narrator do
  @moduledoc """
  A helper module to narrate game play events to the CLI.

  """
  alias Pordle.CLI

  @highlight_color Application.fetch_env!(:pordle, :colors)[:highlight]

  @lines [
    game_won: "🤩 Congratulations, you won in {{moves_made}} guess(es)! 🏆",
    game_lost: "😭 Bad luck, you lost! 💩",
    game_over: "👋 Game over.",
    game_keys: "😀 Your keyboard after {{moves_made}} round(s):",
    game_board: "😀 Your board after {{moves_made}} round(s):",
    make_guess: "🧐 Type your guess and press return: ",
    moves_remaining: "😀 You have {{moves_remaining}} guess(es) remaining.",
    player_move: "\n🤔 You guessed {{move}}.",
    invalid_move: "\n🙄 The word {{move}} is not the correct length.",
    word_not_found: "\n🤭 The word {{word}} was not found in the dictionary.",
    quit: "\n🤬 You suck!",
    help: ~s"""

    😀 Try to guess the word before you run out of guesses.

        - #{CLI.cell("A", :hit)} The letter A is in the word and in the right place.
        - #{CLI.cell("A", :nearly)} The letter A is in the word but it's in the wrong place.
        - #{CLI.cell("A", :miss)} The letter A is not in the word.

      Type `:quit` to quit the game.
    """,
    game_start: ~s"""

      ██████╗  ██████╗ ██████╗ ██████╗ ██╗     ███████╗
      ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
      ██████╔╝██║   ██║██████╔╝██║  ██║██║     █████╗  
      ██╔═══╝ ██║   ██║██╔══██╗██║  ██║██║     ██╔══╝  
      ██║     ╚██████╔╝██║  ██║██████╔╝███████╗███████╗
      ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

      Welcome to Pordle CLI. Type `:help` for help. Type `:quit` to quit. Good luck!
    """
  ]

  @doc """
  Narrates the given line and its arguments.

  """
  def narrate(line, args \\ []) do
    line = Keyword.get(@lines, line) <> "\n"

    Enum.reduce(args, line, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", highlight(value))
    end)
    |> IO.puts()
  end

  @doc """
  Accessor for `@lines`.

  """
  def get_line(line), do: @lines[line]

  defp highlight(char), do: @highlight_color <> "#{char}" <> IO.ANSI.reset()
end

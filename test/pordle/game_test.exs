defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  describe "new/1" do
    test "builds a new game struct from the given opts" do
      game = Game.new(name: "game", puzzle: "crate", moves_allowed: 2)

      assert %Game{
               result: nil,
               finished?: false,
               name: "game",
               puzzle: "crate",
               moves_made: 0,
               moves_allowed: 2,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: %{}
             } = game
    end
  end

  describe "play_move/1" do
    setup do
      game = Game.new(name: "game", puzzle: "crane", moves_allowed: 2)

      assert_initial_state(game)

      {:ok, game: game}
    end

    test "applys the current move to the board", %{game: game} do
      game = prime_move(game, ~w(c r a t e))

      assert {:ok,
              %Game{
                moves_made: 1,
                result: nil,
                finished?: false,
                board: [
                  [hit: "c", hit: "r", hit: "a", miss: "t", hit: "e"],
                  _
                ],
                keyboard: %{"c" => :hit, "r" => :hit, "a" => :hit, "t" => :miss, "e" => :hit}
              }} = Game.play_move(game)
    end

    test "when current move is too short", %{game: game} do
      game = prime_move(game, ~w(c r a t))
      assert {:error, :invalid_move} = Game.play_move(game)
    end

    test "when move is a winning move", %{game: game} do
      game = prime_move(game, ~w(c r a n e))

      assert {:ok,
              %Game{
                moves_made: 1,
                result: :won,
                finished?: true,
                board: [
                  [hit: "c", hit: "r", hit: "a", hit: "n", hit: "e"],
                  _
                ],
                keyboard: %{"c" => :hit, "r" => :hit, "a" => :hit, "n" => :hit, "e" => :hit}
              }} = Game.play_move(game)
    end

    test "when game is finished", %{game: game} do
      game = prime_move(game, ~w(c r a n e))

      {:ok, game} = Game.play_move(game)

      assert {:error, :game_over} = Game.play_move(game)
    end

    test "when moves run out", %{game: game} do
      game = prime_move(game, ~w(c r a t e))

      assert {:ok,
              %Game{
                moves_made: 1,
                result: nil,
                finished?: false,
                board: [
                  [hit: "c", hit: "r", hit: "a", miss: "t", hit: "e"],
                  [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
                ],
                keyboard: %{"c" => :hit, "r" => :hit, "a" => :hit, "t" => :miss, "e" => :hit}
              } = game} = Game.play_move(game)

      game = prime_move(game, ~w(s l a i n))

      assert {:ok,
              %Game{
                moves_made: 2,
                result: :lost,
                finished?: true,
                board: [
                  [hit: "c", hit: "r", hit: "a", miss: "t", hit: "e"],
                  [miss: "s", miss: "l", hit: "a", miss: "i", nearly: "n"]
                ],
                keyboard: %{
                  "c" => :hit,
                  "r" => :hit,
                  "a" => :hit,
                  "t" => :miss,
                  "e" => :hit,
                  "s" => :miss,
                  "l" => :miss,
                  "i" => :miss
                }
              }} = Game.play_move(game)
    end

    test "when word is not in the dictionary", %{game: game} do
      game = prime_move(game, ~w(c r o f t))
      assert {:error, :word_not_found} = Game.play_move(game)
    end

    test "evaluates double letters correctly" do
      game = Game.new(name: "game", puzzle: "tarty", moves_allowed: 9)

      {:ok, game} = game |> prime_move(~w(t a r o t)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(t a t t s)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(s t o t t)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(s t t t y)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(s t t t t)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(t s t f t)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(t s t t f)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(t t t t f)) |> Game.play_move()
      {:ok, game} = game |> prime_move(~w(t a r t y)) |> Game.play_move()

      assert %Game{
               board: [
                 [hit: "t", hit: "a", hit: "r", miss: "o", nearly: "t"],
                 [hit: "t", hit: "a", miss: "t", hit: "t", miss: "s"],
                 [miss: "s", nearly: "t", miss: "o", hit: "t", miss: "t"],
                 [miss: "s", nearly: "t", miss: "t", hit: "t", hit: "y"],
                 [miss: "s", nearly: "t", miss: "t", hit: "t", miss: "t"],
                 [hit: "t", miss: "s", nearly: "t", miss: "f", miss: "t"],
                 [hit: "t", miss: "s", miss: "t", hit: "t", miss: "f"],
                 [hit: "t", miss: "t", miss: "t", hit: "t", miss: "f"],
                 [hit: "t", hit: "a", hit: "r", hit: "t", hit: "y"]
               ]
             } = game
    end
  end

  describe "insert_char/2" do
    setup do
      {:ok, game: Game.new(name: "game", puzzle: "foo", moves_allowed: 2)}
    end

    test "sanitises adds char to the current move", %{game: game} do
      assert %Game{board: [[empty: nil, empty: nil, empty: nil], _]} = game

      {:ok, game} = Game.insert_char(game, " F ")

      assert %Game{board: [[full: "f", empty: nil, empty: nil], _]} = game
    end

    test "does not overflow", %{game: game} do
      {:ok, game} = Game.insert_char(game, "f")
      {:ok, game} = Game.insert_char(game, "o")
      {:ok, game} = Game.insert_char(game, "o")

      assert %Game{board: [[full: "f", full: "o", full: "o"], _]} = game

      {:ok, game} = Game.insert_char(game, "b")

      assert %Game{board: [[full: "f", full: "o", full: "o"], _]} = game
    end
  end

  describe "delete_char/1" do
    setup do
      {:ok,
       game: Game.new(name: "game", puzzle: "foo", board: [[full: "f", full: "o", full: "o"]])}
    end

    test "removes char from end of current move", %{game: game} do
      assert %Game{board: [[full: "f", full: "o", full: "o"]]} = game

      {:ok, game} = Game.delete_char(game)

      assert %Game{board: [[full: "f", full: "o", empty: nil]]} = game
    end

    test "does not overflow", %{game: game} do
      {:ok, game} = Game.delete_char(game)
      {:ok, game} = Game.delete_char(game)
      {:ok, game} = Game.delete_char(game)

      assert %Game{board: [[empty: nil, empty: nil, empty: nil]]} = game

      {:ok, game} = Game.delete_char(game)
      assert %Game{board: [[empty: nil, empty: nil, empty: nil]]} = game
    end
  end

  defp assert_initial_state(game) do
    assert %Game{
             result: nil,
             finished?: false,
             moves_made: 0,
             keyboard: %{},
             board: [
               [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
               [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
             ]
           } = game
  end

  defp prime_move(game, move) do
    Enum.reduce(move, game, fn char, acc ->
      acc
      |> Game.insert_char(char)
      |> then(fn {_, game} -> game end)
    end)
  end
end

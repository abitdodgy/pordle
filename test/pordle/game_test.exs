defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  describe "new/1" do
    test "calculates `puzzle_size` from the given `puzzle`" do
      assert %Game{puzzle: "crate"} = Game.new(name: "game", puzzle: "crate")
    end

    test "builds a new game struct from the given opts" do
      opts = [name: "game", puzzle: "crate", moves_allowed: 2]

      assert %Game{
               name: "game",
               puzzle: "crate",
               moves: [],
               moves_made: 0,
               moves_allowed: 2,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: []
             } = Game.new(opts)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, game: Game.new(name: "game", puzzle: "crate", moves_allowed: 2)}
    end

    test "with a valid move", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "heart")

      assert %Game{
               result: nil,
               moves: ["heart"],
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [{:miss, "h"}, {:nearly, "e"}, {:hit, "a"}, {:nearly, "r"}, {:nearly, "t"}],
                 _
               ],
               keyboard: [
                 {:miss, "h"},
                 {:nearly, "e"},
                 {:hit, "a"},
                 {:nearly, "r"},
                 {:nearly, "t"}
               ]
             } = game
    end

    test "with a winning move", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "crate")

      assert %Game{
               result: :won,
               moves: ["crate"],
               moves_made: 1,
               moves_allowed: 2,
               board: [
                 [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
             } = game
    end

    test "when moves run out", %{game: game} do
      assert_initial_state(game)

      {:ok, %Game{} = game} = Game.play_move(game, "heart")
      {:ok, %Game{} = game} = Game.play_move(game, "slate")

      assert %Game{
               result: :lost,
               moves: ["heart", "slate"],
               moves_made: 2,
               moves_allowed: 2,
               board: [
                 [{:miss, "h"}, {:nearly, "e"}, {:hit, "a"}, {:nearly, "r"}, {:nearly, "t"}],
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
               ],
               keyboard: [
                 {:miss, "h"},
                 {:nearly, "e"},
                 {:hit, "a"},
                 {:nearly, "r"},
                 {:nearly, "t"},
                 {:miss, "s"},
                 {:miss, "l"}
               ]
             } = game
    end

    test "when move is not the correct length", %{game: game} do
      assert_initial_state(game)

      {:error, :invalid_move} = Game.play_move(game, "foo")
      {:error, :invalid_move} = Game.play_move(game, "foobar")
    end

    test "evaluates double letters correctly" do
      game = Game.new(name: "game", puzzle: "tarty", moves_allowed: 9)

      {:ok, %Game{} = game} = Game.play_move(game, "tarot")
      {:ok, %Game{} = game} = Game.play_move(game, "tatts")
      {:ok, %Game{} = game} = Game.play_move(game, "stott")
      {:ok, %Game{} = game} = Game.play_move(game, "sttty")
      {:ok, %Game{} = game} = Game.play_move(game, "stttt")
      {:ok, %Game{} = game} = Game.play_move(game, "tstft")
      {:ok, %Game{} = game} = Game.play_move(game, "tsttf")
      {:ok, %Game{} = game} = Game.play_move(game, "ttttf")
      {:ok, %Game{} = game} = Game.play_move(game, "tarty")

      assert %Game{
               board: [
                 [{:hit, "t"}, {:hit, "a"}, {:hit, "r"}, {:miss, "o"}, {:nearly, "t"}],
                 [{:hit, "t"}, {:hit, "a"}, {:miss, "t"}, {:hit, "t"}, {:miss, "s"}],
                 [{:miss, "s"}, {:nearly, "t"}, {:miss, "o"}, {:hit, "t"}, {:miss, "t"}],
                 [{:miss, "s"}, {:nearly, "t"}, {:miss, "t"}, {:hit, "t"}, {:hit, "y"}],
                 [{:miss, "s"}, {:nearly, "t"}, {:miss, "t"}, {:hit, "t"}, {:miss, "t"}],
                 [{:hit, "t"}, {:miss, "s"}, {:nearly, "t"}, {:miss, "f"}, {:miss, "t"}],
                 [{:hit, "t"}, {:miss, "s"}, {:miss, "t"}, {:hit, "t"}, {:miss, "f"}],
                 [{:hit, "t"}, {:miss, "t"}, {:miss, "t"}, {:hit, "t"}, {:miss, "f"}],
                 [{:hit, "t"}, {:hit, "a"}, {:hit, "r"}, {:hit, "t"}, {:hit, "y"}]
               ]
             } = game

    end

    defp assert_initial_state(game) do
      assert %Game{
               moves: [],
               moves_made: 0,
               keyboard: [],
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = game
    end
  end
end

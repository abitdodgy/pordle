defmodule Pordle.GameTest do
  use ExUnit.Case, async: true

  alias Pordle.Game

  describe "new/1" do
    test "calculates `puzzle_size` from the given `puzzle`" do
      assert %Game{puzzle: "crate", puzzle_size: 5} = Game.new(name: "game", puzzle: "crate")
    end

    test "builds a new game struct from the given opts" do
      opts = [puzzle: "crate", moves_allowed: 2, name: "game"]

      assert %Game{
               puzzle: "crate",
               puzzle_size: 5,
               moves_made: 0,
               moves_allowed: 2,
               board: [
                 [nil: :empty, nil: :empty, nil: :empty, nil: :empty, nil: :empty],
                 [nil: :empty, nil: :empty, nil: :empty, nil: :empty, nil: :empty]
               ],
               keys: []
             } = Game.new(opts)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, game: Game.new(name: "game", puzzle: "crate", moves_allowed: 2)}
    end

    test "with a valid move", %{game: game} do
      {:ok, %Game{} = game} = Game.play_move(game, "heart")

      assert %Game{
               result: nil,
               moves_allowed: 2,
               moves_made: 1,
               board: [
                 [{"h", :miss}, {"e", :nearly}, {"a", :hit}, {"r", :nearly}, {"t", :nearly}], _
               ],
               keys: [{"h", :miss}, {"e", :nearly}, {"a", :hit}, {"r", :nearly}, {"t", :nearly}]
             } = game
    end

    test "with a winning move", %{game: game} do
      {:ok, %Game{} = game} = Game.play_move(game, "crate")

      assert %Game{
               result: :won,
               moves_allowed: 2,
               moves_made: 1,
               board: [
                 [{"c", :hit}, {"r", :hit}, {"a", :hit}, {"t", :hit}, {"e", :hit}], _
               ],
               keys: [{"c", :hit}, {"r", :hit}, {"a", :hit}, {"t", :hit}, {"e", :hit}]
             } = game
    end

    test "when moves run out", %{game: game} do
      {:ok, %Game{} = game} = Game.play_move(game, "heart")
      {:ok, %Game{} = game} = Game.play_move(game, "slate")

      assert %Game{
               result: :lost,
               moves_allowed: 2,
               moves_made: 2,
               board: [
                 [{"h", :miss}, {"e", :nearly}, {"a", :hit}, {"r", :nearly}, {"t", :nearly}],
                 [{"s", :miss}, {"l", :miss}, {"a", :hit}, {"t", :hit}, {"e", :hit}]
               ],
               keys: [{"h", :miss}, {"e", :nearly}, {"a", :hit}, {"r", :nearly}, {"t", :nearly}, {"s", :miss}, {"l", :miss}]
             } = game
    end

    test "when move is not the correct length", %{game: game} do
      {:error, :invalid_move} = Game.play_move(game, "foo")
      {:error, :invalid_move} = Game.play_move(game, "foobar")
    end

    test "evaluates double letters correctly" do
      game = Game.new(name: "foo", puzzle: "small", moves_allowed: 3)

      {:ok, %Game{} = game} = Game.play_move(game, "lllma")
      assert %Game{
               board: [
                 [{"l", :nearly}, {"l", :nearly}, {"l", :miss}, _, _], _, _
               ]
             } = game


      # TODO: Add other scenarios.
      #
      # {:ok, %Game{} = game} = Game.play_move(game, "lllma")
      # assert %Game{
      #          board: [
      #            [{"l", :nearly}, {"l", :nearly}, {"l", :miss}, _, _], _, _
      #          ]
      #        } = game
    end
  end

  describe "finished?/1" do
    test "`false` when game `result` is nil" do
      game = Game.new(name: "foo", puzzle: "foo", result: nil)
      refute Game.finished?(game)
    end

    test "`true` when game `result` is not nil" do
      game = Game.new(name: "foo", puzzle: "foo", result: :won)
      assert Game.finished?(game)
    end
  end
end

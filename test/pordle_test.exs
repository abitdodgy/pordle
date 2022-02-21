defmodule PordleTest do
  use ExUnit.Case

  alias Pordle.Game

  describe "create_game/1" do
    test "returns a game server and a name" do
      {:ok, pid, name} = Pordle.create_game(puzzle: "crate")

      assert Process.alive?(pid)

      assert %Game{name: ^name, puzzle: "crate"} = :sys.get_state(pid)
      assert [{^pid, nil}] = Registry.lookup(Pordle.GameRegistry, {Pordle.GameServer, name})
    end
  end

  describe "delegated functions" do
    setup do
      {:ok, _pid, name} = Pordle.create_game(puzzle: "crate")
      {:ok, name: name}
    end

    test "play_move/2", %{name: name} do
      assert {:ok, %Game{}} = Pordle.play_move(name, "slate")
    end

    test "get_state/1", %{name: name} do
      assert {:ok, %Game{}} = Pordle.get_state(name)
    end

    test "exit/1", %{name: name} do
      assert :ok = Pordle.exit(name)
    end
  end
end

defmodule PordleTest do
  use ExUnit.Case

  alias Pordle.{GameServer, Game}

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
      assert {:ok, %Game{}} = play_move(name, "slate")
    end

    test "insert_char/2", %{name: name} do
      assert {:ok, %Game{}} = Pordle.insert_char(name, "s")
    end

    test "delete_char/1", %{name: name} do
      assert {:ok, %Game{}} = Pordle.delete_char(name)
    end

    test "get_state/1", %{name: name} do
      assert {:ok, %Game{}} = Pordle.get_state(name)
    end

    test "exit/1", %{name: name} do
      assert :ok = Pordle.exit(name)
    end
  end

  defp play_move(game, move) do
    for char <- String.codepoints(move) do
      GameServer.insert_char(game, char)
    end

    GameServer.play_move(game)
  end
end

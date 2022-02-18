defmodule PordleTest do
  use ExUnit.Case

  import Pordle.Test.Helpers, only: [get_name: 0]

  alias Pordle.{GameRegistry, GameServer, Game}

  describe "create_game/1" do
    setup do
      {:ok, opts: [name: get_name(), puzzle: "crate"]}
    end

    test "create_game/1 returns a game server", %{opts: opts} do
      {:ok, server} = Pordle.create_game(opts)

      assert Process.alive?(server)

      assert %Game{name: name, puzzle: "crate"} = :sys.get_state(server)
      assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, name})

      Process.exit(server, :normal)
    end
  end

  describe "delegated functions" do
    setup do
      name = get_name()

      {:ok, _pid} = Pordle.create_game(name: name, puzzle: "crate")
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

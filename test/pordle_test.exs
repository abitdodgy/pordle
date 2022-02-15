defmodule PordleTest do
  use ExUnit.Case

  alias Pordle.{GameRegistry, GameServer, Game}

  test "create_game/1 returns a game server" do
    {:ok, server} = Pordle.create_game()

    assert Process.alive?(server)

    assert %Game{name: name} = :sys.get_state(server)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, name})

    Process.exit(server, :normal)
  end

  test "create_game/1 starts a game server with a custom name" do
    {:ok, server} = Pordle.create_game(name: "123")

    assert Process.alive?(server)

    assert %Game{name: "123"} = :sys.get_state(server)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, "123"})

    Process.exit(server, :normal)
  end
end

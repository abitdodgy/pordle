defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer
  }

  setup do
    name = :rand.uniform(10000)

    on_exit(fn ->
      [{server, _}] = Registry.lookup(GameRegistry, {GameServer, name})
      Process.exit(server, :normal)
    end)

    {:ok, name: name}
  end

  test "start_child/1 starts a new game server process", %{name: name} do
    assert [] = Registry.lookup(GameRegistry, {GameServer, name})

    assert {:ok, server} = GameSupervisor.start_child(name: name)
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, name})
  end
end

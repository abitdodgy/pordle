defmodule Pordle.GameSupervisorTest do
  use ExUnit.Case

  import Pordle.Test.Helpers, only: [get_name: 0]

  alias Pordle.{
    GameSupervisor,
    GameRegistry,
    GameServer
  }

  setup do
    name = get_name()

    on_exit(fn ->
      [{server, _}] = Registry.lookup(GameRegistry, {GameServer, name})
      Process.exit(server, :normal)
    end)

    {:ok, name: name}
  end

  test "start_child/1 starts a new game server process", %{name: name} do
    assert [] = Registry.lookup(GameRegistry, {GameServer, name})

    assert {:ok, server} = GameSupervisor.start_child(name: name, puzzle: "foo")
    assert [{^server, nil}] = Registry.lookup(GameRegistry, {GameServer, name})
  end
end

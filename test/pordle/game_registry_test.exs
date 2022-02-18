defmodule Pordle.GameRegistryTest do
  use ExUnit.Case

  test "via_tuple/1 returns a via tuple for the given game `id`" do
    via_tuple = Pordle.GameRegistry.via_tuple("game id")
    assert {:via, _registry, {_registry_name, "game id"}} = via_tuple
  end
end

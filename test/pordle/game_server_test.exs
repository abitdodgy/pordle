defmodule Pordle.GameServerTest do
  use ExUnit.Case

  alias Pordle.{GameServer, Game}

  describe "start_link/1" do
    test "starts a new game server with the given options" do
      assert {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate")

      assert %Game{
               name: "game",
               puzzle: "crate",
               moves_made: 0,
               moves_allowed: 6,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
                 _,
                 _,
                 _,
                 _,
                 _
               ],
               keyboard: %{}
             } = :sys.get_state(pid)
    end

    test "accepts `moves_allowed` as an option" do
      assert {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate", moves_allowed: 1)

      assert %Game{
               name: "game",
               puzzle: "crate",
               moves_made: 0,
               moves_allowed: 1,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: %{}
             } = :sys.get_state(pid)
    end
  end

  describe "play_move/2" do
    setup do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate", moves_allowed: 2)
      {:ok, name: "game", pid: pid}
    end

    test "when move is valid updates server state", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = state} = play_move(name, "heart")

      assert %Game{
               moves_made: 1,
               board: [
                 [{:miss, "h"}, {:nearly, "e"}, {:hit, "a"}, {:nearly, "r"}, {:nearly, "t"}],
                 _
               ],
               keyboard: %{
                 "h" => :miss,
                 "e" => :nearly,
                 "a" => :hit,
                 "r" => :nearly,
                 "t" => :nearly
               }
             } = state
    end

    test "when move is a winning move", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = state} = play_move(name, "crate")

      assert %Game{
               moves_made: 1,
               result: :won,
               board: [
                 [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: %{
                 "c" => :hit,
                 "r" => :hit,
                 "a" => :hit,
                 "t" => :hit,
                 "e" => :hit
               }
             } = state
    end

    test "when move is a losing move", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:ok, %Game{} = _state} = play_move(name, "slate")
      {:ok, %Game{} = state} = play_move(name, "slate")

      assert %Game{
               moves_made: 2,
               result: :lost,
               board: [
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: %{
                 "s" => :miss,
                 "l" => :miss,
                 "a" => :hit,
                 "t" => :hit,
                 "e" => :hit
               }
             } = state
    end

    test "when move is not in dictionary", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:error, :word_not_found} = play_move(name, "there")
    end

    test "when move is too short", %{name: name, pid: pid} do
      assert_initial_state(pid)

      {:error, :invalid_move} = play_move(name, "foo")

      assert %Game{
               moves_made: 0,
               keyboard: %{},
               board: [
                 [full: "f", full: "o", full: "o", empty: nil, empty: nil],
                 _
               ]
             } = :sys.get_state(pid)
    end

    test "when move is too long ignores last char", %{name: name, pid: pid} do
      assert_initial_state(pid)

      # fooba doesn't exist
      {:error, :word_not_found} = play_move(name, "foobar")

      assert %Game{
               moves_made: 0,
               keyboard: %{},
               board: [
                 [full: "f", full: "o", full: "o", full: "b", full: "a"],
                 _
               ]
             } = :sys.get_state(pid)
    end
  end

  defp assert_initial_state(pid) do
    assert %Game{
             moves_made: 0,
             keyboard: %{},
             board: [
               [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
               _
             ]
           } = :sys.get_state(pid)
  end

  describe "insert_char/2" do
    setup do
      {:ok, _pid} = GameServer.start_link(name: "game", puzzle: "crate", moves_allowed: 1)
      {:ok, name: "game"}
    end

    test "sanitises and adds `char` with type `:full` to `game`", %{name: name} do
      {:ok, %Game{} = state} = GameServer.insert_char(name, " S  ")

      assert %Game{
               board: [
                 [full: "s", empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = state
    end
  end

  describe "delete_char/1" do
    setup do
      {:ok, _pid} = GameServer.start_link(name: "game", puzzle: "crate", moves_allowed: 1)
      {:ok, game} = GameServer.insert_char("game", "s")

      {:ok, name: "game", game: game}
    end

    test "deletes most recently added `char` of type `:full` from `game`", %{
      name: name,
      game: state
    } do
      assert %Game{
               board: [
                 [full: "s", empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = state

      {:ok, %Game{} = state} = GameServer.delete_char(name)

      assert %Game{
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ]
             } = state
    end
  end

  describe "get_state/1" do
    setup do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate")
      {:ok, name: "game", pid: pid}
    end

    test "returns the state for the given server", %{name: name, pid: pid} do
      {:ok, %Game{} = state} = GameServer.get_state(name)
      assert ^state = :sys.get_state(pid)
    end
  end

  describe "exit/1" do
    test "shuts down the process for the given server" do
      {:ok, pid} = GameServer.start_link(name: "game", puzzle: "crate")

      assert Process.alive?(pid)
      assert :ok = GameServer.exit("game")

      # TODO
      # 
      # Without `Process.sleep` this assertion will fail since `Process.alive?/1` returns
      # before GenServer has shutdown.
      # 
      # Find a better way to test this.
      Process.sleep(50)
      refute Process.alive?(pid)
    end
  end

  defp play_move(game, move) do
    for char <- String.codepoints(move) do
      GameServer.insert_char(game, char)
    end

    GameServer.play_move(game)
  end
end

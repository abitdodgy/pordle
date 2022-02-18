defmodule Pordle.GameServerTest do
  use ExUnit.Case

  import Pordle.Test.Helpers, only: [get_name: 0]

  alias Pordle.{GameServer, Game}

  describe "start_link/1" do
    setup do
      {:ok, name: get_name(), puzzle: "crate"}
    end

    test "starts a new game server with the given options", %{
      name: name,
      puzzle: puzzle
    } do
      assert {:ok, server} = GameServer.start_link(name: name, puzzle: puzzle)

      assert %Game{
               name: ^name,
               puzzle: ^puzzle,
               puzzle_size: 5,
               moves: [],
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
               keyboard: []
             } = :sys.get_state(server)

      Process.exit(server, :normal)
    end

    test "accepts `moves_allowed` as an option", %{name: name, puzzle: puzzle} do
      assert {:ok, server} = GameServer.start_link(name: name, puzzle: puzzle, moves_allowed: 1)

      assert %Game{
               name: ^name,
               puzzle: ^puzzle,
               puzzle_size: 5,
               moves: [],
               moves_made: 0,
               moves_allowed: 1,
               board: [
                 [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil]
               ],
               keyboard: []
             } = :sys.get_state(server)

      Process.exit(server, :normal)
    end
  end

  describe "play_move/2" do
    setup do
      name = get_name()

      {:ok, server} = GameServer.start_link(name: name, puzzle: "crate", moves_allowed: 2)

      on_exit(fn ->
        Process.exit(server, :normal)
      end)

      {:ok, name: name, server: server}
    end

    test "when move is valid updates server state", %{name: name, server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = state} = GameServer.play_move(name, "heart")

      assert %Game{
               moves: ["heart"],
               moves_made: 1,
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
             } = state
    end

    test "when move is a winning move", %{name: name, server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = state} = GameServer.play_move(name, "crate")

      assert %Game{
               moves: ["crate"],
               moves_made: 1,
               result: :won,
               board: [
                 [{:hit, "c"}, {:hit, "r"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [
                 {:hit, "c"},
                 {:hit, "r"},
                 {:hit, "a"},
                 {:hit, "t"},
                 {:hit, "e"}
               ]
             } = state
    end

    test "when move is a losing move", %{name: name, server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = _state} = GameServer.play_move(name, "slate")
      {:ok, %Game{} = state} = GameServer.play_move(name, "slate")

      assert %Game{
               moves: ["slate", "slate"],
               moves_made: 2,
               result: :lost,
               board: [
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [
                 {:miss, "s"},
                 {:miss, "l"},
                 {:hit, "a"},
                 {:hit, "t"},
                 {:hit, "e"}
               ]
             } = state
    end

    test "when move is not in dictionary", %{name: name, server: server} do
      assert_initial_state(server)

      {:error, :word_not_found} = GameServer.play_move(name, "there")
    end

    test "when move is not the correct length", %{name: name, server: server} do
      assert_initial_state(server)

      {:error, :invalid_move} = GameServer.play_move(name, "foo")
      {:error, :invalid_move} = GameServer.play_move(name, "foobar")

      assert_initial_state(server)
    end

    test "sanitises input", %{name: name, server: server} do
      assert_initial_state(server)

      {:ok, %Game{} = state} = GameServer.play_move(name, " SLatE ")

      assert %Game{
               moves: ["slate"],
               board: [
                 [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}],
                 _
               ],
               keyboard: [{:miss, "s"}, {:miss, "l"}, {:hit, "a"}, {:hit, "t"}, {:hit, "e"}]
             } = state
    end
  end

  defp assert_initial_state(server) do
    assert %Game{
             moves: [],
             moves_made: 0,
             keyboard: [],
             board: [
               [empty: nil, empty: nil, empty: nil, empty: nil, empty: nil],
               _
             ]
           } = :sys.get_state(server)
  end

  describe "get_state/1" do
    setup do
      name = get_name()

      {:ok, server} = GameServer.start_link(name: name, puzzle: "crate")

      on_exit(fn ->
        Process.exit(server, :normal)
      end)

      {:ok, name: name, server: server}
    end

    test "returns the state for the given server", %{name: name, server: server} do
      {:ok, %Game{} = state} = GameServer.get_state(name)
      assert ^state = :sys.get_state(server)
    end
  end

  describe "exit/1" do
    test "shuts down the process for the given server" do
      name = get_name()
      {:ok, server} = GameServer.start_link(name: name, puzzle: "crate")

      assert Process.alive?(server)
      assert :ok = GameServer.exit(name)

      refute Process.alive?(server)
    end
  end
end

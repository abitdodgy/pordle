defmodule Pordle.GameServerTest do
  use ExUnit.Case, async: true

  alias Pordle.{GameServer, Game}

  test "start_link/1 starts a new game server without any options" do
    assert {:ok, server} = GameServer.start_link([])

    %Game{
      name: game_name,
      puzzle: puzzle,
      puzzle_size: 5,
      moves_allowed: 6,
      moves_made: 0,
      keys: [],
      result: nil
    } = :sys.get_state(server)

    assert is_binary(game_name)
    assert is_binary(puzzle)

    Process.exit(server, :normal)
  end

  test "start_link/1 accepts a custom `name`, `puzzle`, and `moves_allowed` as options" do
    assert {:ok, server} =
             GameServer.start_link(name: "custom", puzzle: "amazing", moves_allowed: 1)

    %Game{
      name: "custom",
      puzzle: "amazing",
      puzzle_size: 7,
      moves_allowed: 1,
      board: [
        [
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty
        ]
      ]
    } = :sys.get_state(server)

    Process.exit(server, :normal)
  end

  test "start_link/1 accepts a `puzzle_size` option" do
    assert {:ok, server} = GameServer.start_link(puzzle_size: 6, moves_allowed: 1)

    %Game{
      puzzle: puzzle,
      puzzle_size: 6,
      board: [
        [
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty,
          nil: :empty
        ]
      ]
    } = :sys.get_state(server)

    assert is_binary(puzzle)

    Process.exit(server, :normal)
  end

  test "start_link/1 ignores `puzzle_size` when a `puzzle` is provided" do
    assert {:ok, server} = GameServer.start_link(puzzle: "amazing", puzzle_size: 3)

    %Game{puzzle: "amazing", puzzle_size: 7} = :sys.get_state(server)

    Process.exit(server, :normal)
  end

  test "play_move/1" do
    assert {:ok, server} = GameServer.start_link(puzzle: "crate", moves_allowed: 2)

    {:ok,
     %Game{
       board: [
         [
           {"s", :miss},
           {"l", :miss},
           {"a", :hit},
           {"t", :hit},
           {"e", :hit}
         ],
         [
           nil: :empty,
           nil: :empty,
           nil: :empty,
           nil: :empty,
           nil: :empty
         ]
       ],
       keys: [{"s", :miss}, {"l", :miss}, {"a", :hit}, {"t", :hit}, {"e", :hit}]
     }} = GameServer.play_move(server, "slate")

    Process.exit(server, :normal)
  end

  test "play_move/1 when move is not in dictionary" do
    assert {:ok, server} = GameServer.start_link(puzzle: "crate", moves_allowed: 2)

    {:error, :word_not_found} = GameServer.play_move(server, "there")

    Process.exit(server, :normal)
  end

  test "get_state/1 returns the state of the given server"
end

defmodule PointingPoker.RoomsTest do
  use ExUnit.Case, async: true

  alias PointingPoker.Rooms

  defp unique_room(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  defp spawn_participant do
    spawn(fn ->
      receive do
        :stop -> :ok
      end
    end)
  end

  describe "generate_room_id/0" do
    test "generates valid RFC 4122 v4 UUIDs" do
      id1 = Rooms.generate_room_id()
      id2 = Rooms.generate_room_id()

      assert id1 != id2

      uuid_v4_regex =
        ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

      assert Regex.match?(uuid_v4_regex, id1)
      assert Regex.match?(uuid_v4_regex, id2)
    end
  end

  describe "room lifecycle and voting" do
    test "tracks participants, names, arbitrary vote strings, tallies, show and clear" do
      room_id = unique_room("lifecycle")
      Rooms.subscribe(room_id)

      p1 = spawn_participant()
      p2 = spawn_participant()
      p3 = spawn_participant()

      on_exit(fn ->
        send(p1, :stop)
        send(p2, :stop)
        send(p3, :stop)
      end)

      assert {:ok, id1, snap} = Rooms.join(room_id, p1, "Alice")
      assert snap.room_id == room_id
      assert snap.show_votes == false
      assert snap.participant_count == 1
      assert snap.voted_count == 0
      assert [%{id: ^id1, name: "Alice", vote: nil, voted?: false}] = snap.participants

      assert {:ok, _id2, _} = Rooms.join(room_id, p2, "   ")
      assert {:ok, _id3, snap} = Rooms.join(room_id, p3, "Charlie")
      assert Enum.map(snap.participants, & &1.name) == ["Alice", "Anonymous", "Charlie"]

      assert {:ok, snap} = Rooms.set_name(room_id, p2, "Bob")
      assert Enum.map(snap.participants, & &1.name) == ["Alice", "Bob", "Charlie"]

      assert {:ok, _} = Rooms.vote(room_id, p1, "XL")
      assert {:ok, _} = Rooms.vote(room_id, p2, "  XL  ")
      assert {:ok, snap} = Rooms.vote(room_id, p3, "needs spike ☕")

      assert snap.voted_count == 3
      assert snap.show_votes == false

      assert snap.tallies == [
               %{vote: "XL", count: 2},
               %{vote: "needs spike ☕", count: 1}
             ]

      assert {:ok, snap} = Rooms.show_votes(room_id)
      assert snap.show_votes == true
      assert_receive {:room_updated, %{show_votes: true}}

      assert {:ok, snap} = Rooms.clear_votes(room_id)
      assert snap.show_votes == false
      assert snap.voted_count == 0
      assert snap.tallies == []
      assert Enum.all?(snap.participants, &(&1.vote == nil and not &1.voted?))
    end

    test "removes disconnected participants and cleans up empty rooms" do
      room_id = unique_room("cleanup")
      Rooms.subscribe(room_id)

      p1 = spawn_participant()
      p2 = spawn_participant()

      assert {:ok, _id1, _} = Rooms.join(room_id, p1, "Alice")
      assert {:ok, _id2, _} = Rooms.join(room_id, p2, "Bob")

      [{room_pid, _}] = Registry.lookup(PointingPoker.Rooms.Registry, room_id)
      ref = Process.monitor(room_pid)

      send(p1, :stop)

      assert_receive {:room_updated, %{participant_count: 1, participants: [%{name: "Bob"}]}},
                     1000

      send(p2, :stop)

      assert_receive {:DOWN, ^ref, :process, ^room_pid, :normal}, 1000
      refute Process.alive?(room_pid)

      # Rejoining starts a fresh room cleanly
      p3 = spawn_participant()
      on_exit(fn -> send(p3, :stop) end)

      assert {:ok, _id3, snap} = Rooms.join(room_id, p3, "Dana")
      assert snap.participant_count == 1
      assert snap.show_votes == false

      [{new_room_pid, _}] = Registry.lookup(PointingPoker.Rooms.Registry, room_id)
      assert new_room_pid != room_pid
    end
  end
end

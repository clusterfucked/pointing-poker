defmodule PointingPoker.Rooms.RoomServer do
  @moduledoc """
  Holds live pointing-poker state for a single room.

  Monitors each connected participant process so departures automatically remove
  the participant, and stops itself cleanly once the last participant leaves.
  """

  use GenServer, restart: :temporary

  @default_name "Anonymous"

  def start_link(room_id) when is_binary(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via(room_id))
  end

  def via(room_id) do
    {:via, Registry, {PointingPoker.Rooms.Registry, room_id}}
  end

  def empty_snapshot(room_id) do
    %{
      room_id: room_id,
      show_votes: false,
      participants: [],
      tallies: [],
      voted_count: 0,
      participant_count: 0
    }
  end

  @impl true
  def init(room_id) do
    state = %{
      room_id: room_id,
      show_votes: false,
      participants: %{},
      monitors: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, build_snapshot(state), state}
  end

  def handle_call({:join, pid, name}, _from, state) do
    normalized_name = normalize_name(name)

    {participant_id, state} =
      case Map.get(state.participants, pid) do
        nil ->
          ref = Process.monitor(pid)
          id = "p-#{System.unique_integer([:positive, :monotonic])}"

          participant = %{
            id: id,
            name: normalized_name,
            vote: nil,
            joined_at: System.monotonic_time()
          }

          next_state = %{
            state
            | participants: Map.put(state.participants, pid, participant),
              monitors: Map.put(state.monitors, pid, ref)
          }

          {id, next_state}

        existing ->
          updated = %{existing | name: normalized_name}
          {existing.id, put_in(state.participants[pid], updated)}
      end

    snapshot = broadcast_update(state)
    {:reply, {:ok, participant_id, snapshot}, state}
  end

  def handle_call({:set_name, pid, name}, _from, state) do
    case Map.get(state.participants, pid) do
      nil ->
        {:reply, {:error, :not_joined}, state}

      participant ->
        updated = %{participant | name: normalize_name(name)}
        state = put_in(state.participants[pid], updated)
        snapshot = broadcast_update(state)
        {:reply, {:ok, snapshot}, state}
    end
  end

  def handle_call({:vote, pid, vote}, _from, state) do
    case Map.get(state.participants, pid) do
      nil ->
        {:reply, {:error, :not_joined}, state}

      participant ->
        normalized_vote = normalize_vote(vote)
        updated = %{participant | vote: normalized_vote}
        state = put_in(state.participants[pid], updated)
        snapshot = broadcast_update(state)
        {:reply, {:ok, snapshot}, state}
    end
  end

  def handle_call(:show_votes, _from, state) do
    state = %{state | show_votes: true}
    snapshot = broadcast_update(state)
    {:reply, {:ok, snapshot}, state}
  end

  def handle_call(:clear_votes, _from, state) do
    cleared_participants =
      Map.new(state.participants, fn {pid, participant} ->
        {pid, %{participant | vote: nil}}
      end)

    state = %{state | show_votes: false, participants: cleared_participants}
    snapshot = broadcast_update(state)
    {:reply, {:ok, snapshot}, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = %{
      state
      | participants: Map.delete(state.participants, pid),
        monitors: Map.delete(state.monitors, pid)
    }

    if map_size(state.participants) == 0 do
      {:stop, :normal, state}
    else
      broadcast_update(state)
      {:noreply, state}
    end
  end

  defp broadcast_update(state) do
    snapshot = build_snapshot(state)

    Phoenix.PubSub.broadcast(
      PointingPoker.PubSub,
      PointingPoker.Rooms.topic(state.room_id),
      {:room_updated, snapshot}
    )

    snapshot
  end

  defp build_snapshot(state) do
    participants =
      state.participants
      |> Map.values()
      |> Enum.sort_by(& &1.joined_at)
      |> Enum.map(fn p ->
        %{
          id: p.id,
          name: p.name,
          vote: p.vote,
          voted?: not is_nil(p.vote)
        }
      end)

    tallies =
      participants
      |> Enum.map(& &1.vote)
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {vote, count} -> {-count, vote} end)
      |> Enum.map(fn {vote, count} -> %{vote: vote, count: count} end)

    %{
      room_id: state.room_id,
      show_votes: state.show_votes,
      participants: participants,
      tallies: tallies,
      voted_count: Enum.count(participants, & &1.voted?),
      participant_count: length(participants)
    }
  end

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> @default_name
      trimmed -> trimmed
    end
  end

  defp normalize_name(_), do: @default_name

  defp normalize_vote(vote) when is_binary(vote) do
    case String.trim(vote) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_vote(_), do: nil
end

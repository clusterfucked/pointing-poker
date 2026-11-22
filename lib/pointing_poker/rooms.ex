defmodule PointingPoker.Rooms do
  @moduledoc """
  Context for managing ephemeral pointing poker rooms in memory.
  """

  alias PointingPoker.Rooms.RoomServer

  @doc """
  Generates a random RFC 4122 version 4 UUID string for a new room.
  """
  def generate_room_id do
    <<a::48, _::4, b::12, _::2, c::62>> = :crypto.strong_rand_bytes(16)
    <<u1::32, u2::16, u3::16, u4::16, u5::48>> = <<a::48, 4::4, b::12, 2::2, c::62>>

    [
      hex(u1, 8),
      hex(u2, 4),
      hex(u3, 4),
      hex(u4, 4),
      hex(u5, 12)
    ]
    |> Enum.join("-")
  end

  @doc """
  Returns the PubSub topic name for a room.
  """
  def topic(room_id) when is_binary(room_id), do: "room:" <> room_id

  @doc """
  Subscribes the calling process to updates for `room_id`.
  """
  def subscribe(room_id) when is_binary(room_id) do
    Phoenix.PubSub.subscribe(PointingPoker.PubSub, topic(room_id))
  end

  @doc """
  Returns the current snapshot for a room without joining it.
  If the room is not active, returns an empty snapshot.
  """
  def get_state(room_id) when is_binary(room_id) do
    case lookup_room(room_id) do
      {:ok, pid} ->
        try do
          GenServer.call(pid, :get_state)
        catch
          :exit, _ -> RoomServer.empty_snapshot(room_id)
        end

      :error ->
        RoomServer.empty_snapshot(room_id)
    end
  end

  @doc """
  Joins a room as `pid` (defaults to `self()`), starting the room server if needed.
  Returns `{:ok, participant_id, snapshot}`.
  """
  def join(room_id, pid \\ self(), name \\ "Anonymous") when is_binary(room_id) and is_pid(pid) do
    ensure_and_call(room_id, {:join, pid, name}, 3)
  end

  @doc """
  Updates the participant's display name in the room.
  """
  def set_name(room_id, pid \\ self(), name) when is_binary(room_id) and is_pid(pid) do
    call_existing(room_id, {:set_name, pid, name})
  end

  @doc """
  Submits (or clears, if blank/nil) a vote string for the participant.
  """
  def vote(room_id, pid \\ self(), vote) when is_binary(room_id) and is_pid(pid) do
    call_existing(room_id, {:vote, pid, vote})
  end

  @doc """
  Reveals all submitted votes in the room.
  """
  def show_votes(room_id) when is_binary(room_id) do
    call_existing(room_id, :show_votes)
  end

  @doc """
  Clears all votes and hides votes for the next round.
  """
  def clear_votes(room_id) when is_binary(room_id) do
    call_existing(room_id, :clear_votes)
  end

  defp ensure_and_call(room_id, message, attempts) when attempts > 0 do
    pid = ensure_started!(room_id)

    try do
      GenServer.call(pid, message)
    catch
      :exit, {:noproc, _} -> ensure_and_call(room_id, message, attempts - 1)
      :exit, {:normal, _} -> ensure_and_call(room_id, message, attempts - 1)
      :exit, {:shutdown, _} -> ensure_and_call(room_id, message, attempts - 1)
    end
  end

  defp ensure_started!(room_id) do
    case lookup_room(room_id) do
      {:ok, pid} ->
        pid

      :error ->
        case DynamicSupervisor.start_child(
               PointingPoker.Rooms.RoomSupervisor,
               {RoomServer, room_id}
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  defp call_existing(room_id, message) do
    case lookup_room(room_id) do
      {:ok, pid} ->
        try do
          GenServer.call(pid, message)
        catch
          :exit, _ -> {:error, :not_found}
        end

      :error ->
        {:error, :not_found}
    end
  end

  defp lookup_room(room_id) do
    case Registry.lookup(PointingPoker.Rooms.Registry, room_id) do
      [{pid, _}] ->
        if Process.alive?(pid), do: {:ok, pid}, else: :error

      [] ->
        :error
    end
  end

  defp hex(int, width) do
    int
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(width, "0")
  end
end

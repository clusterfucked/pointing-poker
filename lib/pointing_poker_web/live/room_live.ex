defmodule PointingPokerWeb.RoomLive do
  use PointingPokerWeb, :live_view

  alias PointingPoker.Rooms

  @impl true
  def mount(%{"room_id" => room_id}, _session, socket) do
    {my_id, room} =
      if connected?(socket) do
        Rooms.subscribe(room_id)
        {:ok, participant_id, snapshot} = Rooms.join(room_id, self(), "Anonymous")
        {participant_id, snapshot}
      else
        {nil, Rooms.get_state(room_id)}
      end

    {:ok,
     socket
     |> assign(:page_title, room_id)
     |> assign(:room_id, room_id)
     |> assign(:my_id, my_id)
     |> assign(:room, room)
     |> assign(:my_vote, find_my_vote(room.participants, my_id))
     |> assign(:copy_flash_timer, nil)
     |> assign(:name_form, to_form(%{"name" => ""}, as: :participant))
     |> assign(:vote_form, to_form(%{"value" => ""}, as: :vote))}
  end

  @impl true
  def handle_event("set_name", %{"participant" => %{"name" => name}}, socket) do
    apply_name_change(socket, name)
  end

  def handle_event("set_name", %{"name" => name}, socket) do
    apply_name_change(socket, name)
  end

  def handle_event("submit_vote", %{"vote" => %{"value" => value}}, socket) do
    Rooms.vote(socket.assigns.room_id, self(), value)

    {:noreply,
     socket
     |> assign(:vote_form, to_form(%{"value" => value}, as: :vote))}
  end

  def handle_event("show_votes", _params, socket) do
    Rooms.show_votes(socket.assigns.room_id)
    {:noreply, socket}
  end

  def handle_event("clear_votes", _params, socket) do
    Rooms.clear_votes(socket.assigns.room_id)

    {:noreply,
     socket
     |> assign(:vote_form, to_form(%{"value" => ""}, as: :vote))}
  end

  def handle_event("link_copied", _params, socket) do
    if ref = socket.assigns.copy_flash_timer, do: Process.cancel_timer(ref)
    ref = Process.send_after(self(), :clear_copy_flash, 2500)

    {:noreply,
     socket
     |> assign(:copy_flash_timer, ref)
     |> put_flash(:info, "Link copied")}
  end

  @impl true
  def handle_info(:clear_copy_flash, socket) do
    {:noreply,
     socket
     |> assign(:copy_flash_timer, nil)
     |> clear_flash(:info)}
  end

  def handle_info({:room_updated, snapshot}, socket) do
    previous_vote = socket.assigns.my_vote
    current_vote = find_my_vote(snapshot.participants, socket.assigns.my_id)

    socket =
      socket
      |> assign(:room, snapshot)
      |> assign(:my_vote, current_vote)

    socket =
      if not is_nil(previous_vote) and is_nil(current_vote) do
        assign(socket, :vote_form, to_form(%{"value" => ""}, as: :vote))
      else
        socket
      end

    {:noreply, socket}
  end

  defp apply_name_change(socket, name) do
    Rooms.set_name(socket.assigns.room_id, self(), name)

    {:noreply,
     socket
     |> assign(:name_form, to_form(%{"name" => name}, as: :participant))}
  end

  defp find_my_vote(_participants, nil), do: nil

  defp find_my_vote(participants, my_id) do
    case Enum.find(participants, &(&1.id == my_id)) do
      nil -> nil
      participant -> participant.vote
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <%!-- Room Header (click anywhere to copy room link) --%>
        <button
          id="copy-room-url-btn"
          type="button"
          phx-hook="CopyRoomUrl"
          title="Copy room link"
          aria-label="Copy room link"
          class="w-full flex items-center justify-between gap-3 pb-5 border-b border-base-content/10 text-left cursor-pointer group"
        >
          <h1 id="room-title" class="text-2xl sm:text-3xl font-bold tracking-tight break-all">
            {@room_id}
          </h1>

          <span class="shrink-0 text-base-content/40 group-hover:text-base-content transition-colors">
            <.icon name="hero-link" class="size-5" data-copy-icon />
            <.icon name="hero-check" class="size-5 text-success hidden" data-copied-icon />
          </span>
        </button>

        <%!-- Name & Vote Inputs --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
          <.form
            for={@name_form}
            id="name-form"
            phx-change="set_name"
            phx-submit="set_name"
            class="space-y-1.5"
          >
            <label
              for="participant-name-input"
              class="block text-sm font-medium text-base-content/70"
            >
              Name
            </label>
            <input
              type="text"
              id="participant-name-input"
              name={@name_form[:name].name}
              value={@name_form[:name].value}
              placeholder="Your name"
              autocomplete="name"
              phx-hook="RememberName"
              phx-debounce="200"
              class="input input-bordered w-full"
            />
          </.form>

          <.form
            for={@vote_form}
            id="vote-form"
            phx-submit="submit_vote"
            class="space-y-1.5"
          >
            <label for="vote-input" class="block text-sm font-medium text-base-content/70">
              Vote
            </label>
            <div class="flex gap-2 items-center">
              <input
                type="text"
                id="vote-input"
                name={@vote_form[:value].name}
                value={@vote_form[:value].value}
                placeholder="Enter any vote"
                autocomplete="off"
                class="input input-bordered flex-1"
              />
              <button id="submit-vote-btn" type="submit" class="btn btn-primary">
                Vote
              </button>
            </div>
          </.form>
        </div>

        <%!-- Participants --%>
        <section id="participants-section" class="space-y-3">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <h2 class="text-base font-semibold">
              Participants
              <span class="text-base-content/50 font-normal ml-1">({@room.participant_count})</span>
            </h2>

            <div class="flex items-center gap-2">
              <button
                id="show-votes-btn"
                type="button"
                phx-click="show_votes"
                disabled={@room.show_votes}
                class="btn btn-sm btn-primary"
              >
                Show Votes
              </button>

              <button
                id="clear-votes-btn"
                type="button"
                phx-click="clear_votes"
                class="btn btn-sm btn-outline btn-error"
              >
                Clear Votes
              </button>
            </div>
          </div>

          <div class="overflow-x-auto border border-base-content/10 rounded-box">
            <table id="participants-table" class="table">
              <thead>
                <tr>
                  <th class="w-14">Status</th>
                  <th>Name</th>
                  <th class="text-right">Vote</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={participant <- @room.participants}
                  id={"participant-#{participant.id}"}
                  class={participant.id == @my_id && "bg-primary/5"}
                >
                  <td>
                    <span
                      :if={participant.voted?}
                      class="inline-flex items-center text-success"
                      title="Vote submitted"
                    >
                      <.icon name="hero-check-circle-solid" class="size-5" />
                    </span>
                    <span
                      :if={!participant.voted?}
                      class="inline-flex items-center text-base-content/30"
                      title="Not voted yet"
                    >
                      <.icon name="hero-clock" class="size-5" />
                    </span>
                  </td>
                  <td class="font-medium">
                    <div class="flex items-center gap-2">
                      <span>{participant.name}</span>
                      <span
                        :if={participant.id == @my_id}
                        class="badge badge-xs badge-primary badge-soft"
                      >
                        You
                      </span>
                    </div>
                  </td>
                  <td class="text-right">
                    <%= cond do %>
                      <% @room.show_votes and participant.voted? -> %>
                        <span class="badge badge-lg badge-primary font-mono font-semibold">
                          {participant.vote}
                        </span>
                      <% participant.voted? -> %>
                        <span class="badge badge-success badge-soft">Voted</span>
                      <% true -> %>
                        <span class="text-base-content/40 text-sm">—</span>
                    <% end %>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <%!-- Vote Summary (only when votes are revealed) --%>
        <section :if={@room.show_votes} id="votes-summary" class="space-y-3">
          <h2 class="text-base font-semibold">Summary</h2>

          <%= if @room.tallies == [] do %>
            <p class="text-sm text-base-content/60">No votes submitted.</p>
          <% else %>
            <div class="overflow-x-auto border border-base-content/10 rounded-box">
              <table id="summary-table" class="table">
                <thead>
                  <tr>
                    <th>Vote</th>
                    <th class="text-right">Count</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={tally <- @room.tallies}>
                    <td>
                      <span class="badge badge-lg badge-primary badge-soft font-mono font-semibold">
                        {tally.vote}
                      </span>
                    </td>
                    <td class="text-right font-semibold tabular-nums">
                      {tally.count}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </section>
      </div>
    </Layouts.app>
    """
  end
end

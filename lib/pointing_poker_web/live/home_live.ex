defmodule PointingPokerWeb.HomeLive do
  use PointingPokerWeb, :live_view

  alias PointingPoker.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Pointing Poker")
     |> assign(:join_form, to_form(%{"room_name" => ""}, as: :room))}
  end

  @impl true
  def handle_event("create_room", _params, socket) do
    room_id = Rooms.generate_room_id()
    {:noreply, push_navigate(socket, to: ~p"/#{room_id}")}
  end

  def handle_event("join_room", %{"room" => %{"room_name" => room_name}}, socket) do
    case String.trim(room_name) do
      "" ->
        {:noreply, socket}

      trimmed ->
        {:noreply, push_navigate(socket, to: ~p"/#{trimmed}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-sm py-16 sm:py-24 space-y-6">
        <h1 class="text-3xl font-bold tracking-tight text-center">Pointing Poker</h1>

        <button
          id="create-room-btn"
          type="button"
          phx-click="create_room"
          class="btn btn-primary btn-lg w-full"
        >
          Create Room
        </button>

        <div class="divider text-xs uppercase tracking-wider text-base-content/50 my-0">or</div>

        <.form
          for={@join_form}
          id="join-room-form"
          phx-submit="join_room"
          class="flex w-full gap-2 items-center"
        >
          <input
            type="text"
            id={@join_form[:room_name].id}
            name={@join_form[:room_name].name}
            value={@join_form[:room_name].value}
            placeholder="Room name"
            autocomplete="off"
            class="input input-bordered flex-1"
          />
          <button type="submit" class="btn btn-neutral">
            Join
          </button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end

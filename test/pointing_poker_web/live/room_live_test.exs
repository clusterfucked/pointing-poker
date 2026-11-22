defmodule PointingPokerWeb.RoomLiveTest do
  use PointingPokerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp unique_room(name) do
    "#{name}-#{System.unique_integer([:positive])}"
  end

  test "accepts any string path param and displays it as the title and heading", %{conn: conn} do
    room_name = unique_room("Sprint 42 Planning")
    {:ok, view, html} = live(conn, ~p"/#{room_name}")

    assert page_title(view) =~ room_name
    assert html =~ room_name
    assert element(view, "#room-title") |> render() =~ room_name
  end

  test "syncs names, hidden votes, revealed votes, summary tallies, and clear across users", %{
    conn: conn
  } do
    room_id = unique_room("sync-room")

    {:ok, alice, _} = live(conn, ~p"/#{room_id}")
    {:ok, bob, _} = live(conn, ~p"/#{room_id}")
    {:ok, charlie, _} = live(conn, ~p"/#{room_id}")

    # Set names
    alice |> form("#name-form", participant: %{name: "Alice"}) |> render_change()
    bob |> form("#name-form", participant: %{name: "Bob"}) |> render_change()
    charlie |> form("#name-form", participant: %{name: "Charlie"}) |> render_change()

    # Everyone sees all participants
    for view <- [alice, bob, charlie] do
      rendered = render(view)
      assert rendered =~ "Alice"
      assert rendered =~ "Bob"
      assert rendered =~ "Charlie"
      assert rendered =~ "(3)"
    end

    # Cast arbitrary string votes
    alice |> form("#vote-form", vote: %{value: "XL-custom"}) |> render_submit()
    bob |> form("#vote-form", vote: %{value: "XL-custom"}) |> render_submit()
    charlie |> form("#vote-form", vote: %{value: "needs spike"}) |> render_submit()

    # Before revealing: voted indicator is shown, summary is hidden, and other users' votes are NOT leaked
    alice_html = render(alice)
    assert alice_html =~ "Voted"
    refute has_element?(alice, "#votes-summary")
    refute alice_html =~ "needs spike"

    charlie_html = render(charlie)
    assert charlie_html =~ "Voted"
    refute has_element?(charlie, "#votes-summary")
    refute charlie_html =~ "XL-custom"

    # Alice clicks Show Votes
    alice |> element("#show-votes-btn") |> render_click()

    # All participants see votes next to names and the summed summary table
    for view <- [alice, bob, charlie] do
      assert has_element?(view, "#votes-summary")
      participants_html = view |> element("#participants-table") |> render()
      assert participants_html =~ "XL-custom"
      assert participants_html =~ "needs spike"

      summary_html = view |> element("#summary-table") |> render()
      assert summary_html =~ "XL-custom"
      assert summary_html =~ "2"
      assert summary_html =~ "needs spike"
      assert summary_html =~ "1"
    end

    # A late joiner (Dana) immediately gets the exact same live revealed state
    {:ok, dana, dana_html} = live(conn, ~p"/#{room_id}")
    assert dana_html =~ "Alice"
    assert dana_html =~ "Bob"
    assert dana_html =~ "Charlie"
    assert dana_html =~ "XL-custom"
    assert dana_html =~ "needs spike"
    assert has_element?(dana, "#votes-summary")

    # Bob clicks Clear Votes -> hides summary and resets all votes for everyone
    bob |> element("#clear-votes-btn") |> render_click()

    for view <- [alice, bob, charlie, dana] do
      refute has_element?(view, "#votes-summary")
      refute element(view, "#participants-table") |> render() =~ "Voted"
    end
  end

  test "late joiner receives in-progress hidden voting state and sees departures live", %{
    conn: conn
  } do
    room_id = unique_room("late-join")

    {:ok, alice, _} = live(conn, ~p"/#{room_id}")
    alice |> form("#name-form", participant: %{name: "Alice"}) |> render_change()
    alice |> form("#vote-form", vote: %{value: "5"}) |> render_submit()

    # Bob joins after Alice has voted (before reveal)
    {:ok, bob, bob_html} = live(conn, ~p"/#{room_id}")
    assert bob_html =~ "Alice"
    assert bob_html =~ "Voted"
    refute has_element?(bob, "#votes-summary")
    refute element(bob, "#participants-table") |> render() =~ ">5<"

    # Alice disconnects -> Bob sees Alice removed live
    GenServer.stop(alice.pid)
    Process.sleep(50)

    bob_after = render(bob)
    refute bob_after =~ "Alice"
    assert bob_after =~ "(1)"
  end

  test "shows built-in flash notification when room link is copied", %{conn: conn} do
    room_id = unique_room("copy-flash")
    {:ok, view, _} = live(conn, ~p"/#{room_id}")

    render_hook(view, "link_copied", %{})
    assert has_element?(view, "#flash-info", "Link copied")
  end
end

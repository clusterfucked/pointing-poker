defmodule PointingPokerWeb.HomeLiveTest do
  use PointingPokerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders landing page and creates a random UUID room", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Pointing Poker"
    assert has_element?(view, "#create-room-btn")

    {:error, {:live_redirect, %{to: "/" <> room_id}}} =
      view
      |> element("#create-room-btn")
      |> render_click()

    uuid_v4_regex =
      ~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

    assert Regex.match?(uuid_v4_regex, room_id)
  end

  test "allows jumping to a named room from the landing page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    {:error, {:live_redirect, %{to: "/sprint-42"}}} =
      view
      |> form("#join-room-form", room: %{room_name: "sprint-42"})
      |> render_submit()
  end
end

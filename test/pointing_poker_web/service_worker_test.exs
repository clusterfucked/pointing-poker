defmodule PointingPokerWeb.ServiceWorkerTest do
  use PointingPokerWeb.ConnCase, async: true

  test "GET /service-worker.js returns 404 so browsers unregister legacy service workers", %{
    conn: conn
  } do
    conn = get(conn, "/service-worker.js")
    assert conn.status == 404
  end
end

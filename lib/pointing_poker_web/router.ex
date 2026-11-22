defmodule PointingPokerWeb.Router do
  use PointingPokerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PointingPokerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  if Application.compile_env(:pointing_poker, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PointingPokerWeb.Telemetry
    end
  end

  scope "/", PointingPokerWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/:room_id", RoomLive, :show
  end
end

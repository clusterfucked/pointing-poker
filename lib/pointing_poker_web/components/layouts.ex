defmodule PointingPokerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PointingPokerWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-base-100">
      <header class="navbar bg-base-100/90 backdrop-blur sticky top-0 z-40 border-b border-base-content/10 px-4 sm:px-6 lg:px-8">
        <div class="navbar-start">
          <.link
            navigate={~p"/"}
            class="text-lg font-bold tracking-tight hover:opacity-80 transition-opacity"
          >
            Pointing Poker
          </.link>
        </div>

        <div class="navbar-end gap-2">
          <.theme_toggle />
        </div>
      </header>

      <main class="flex-1 px-4 py-8 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-3xl">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle" aria-label="Toggle theme">
        <div class="relative size-5">
          <.icon
            name="hero-sun"
            class="absolute inset-0 size-full transition-all scale-100 rotate-0 dark:scale-0 dark:rotate-90"
          />
          <.icon
            name="hero-moon"
            class="absolute inset-0 size-full transition-all scale-0 -rotate-90 dark:scale-100 dark:rotate-0"
          />
        </div>
        <span class="sr-only">Toggle theme</span>
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu p-2 shadow-xl bg-base-100 rounded-box w-32 border border-base-content/10"
      >
        <li>
          <button
            type="button"
            phx-click={JS.dispatch("phx:set-theme") |> JS.dispatch("pointing-poker:close-menu")}
            data-phx-theme="light"
          >
            <.icon name="hero-sun-micro" class="size-4" /> Light
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click={JS.dispatch("phx:set-theme") |> JS.dispatch("pointing-poker:close-menu")}
            data-phx-theme="dark"
          >
            <.icon name="hero-moon-micro" class="size-4" /> Dark
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click={JS.dispatch("phx:set-theme") |> JS.dispatch("pointing-poker:close-menu")}
            data-phx-theme="system"
          >
            <.icon name="hero-computer-desktop-micro" class="size-4" /> System
          </button>
        </li>
      </ul>
    </div>
    """
  end
end

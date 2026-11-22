import Config

# For development, we disable any cache and enable
# debugging and code reloading.
config :pointing_poker, PointingPokerWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "B7pK9xL2mQ8vR4wN6yT1zF5cH3jD0sA8eU2gW9kP4rX7nM1bV6qZ3tY0fJ5hC8dL",
  watchers: [
    esbuild: {Esbuild, :run, [:pointing_poker, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :run, [:pointing_poker, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :pointing_poker, PointingPokerWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/pointing_poker_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard
config :pointing_poker, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  # Changing this configuration will require mix clean and a full recompile.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

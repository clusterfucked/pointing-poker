import Config

config :pointing_poker,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :pointing_poker, PointingPokerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PointingPokerWeb.ErrorHTML, json: PointingPokerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PointingPoker.PubSub,
  live_view: [signing_salt: "p0k3rL1v"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.27.2",
  path: System.find_executable("esbuild"),
  pointing_poker: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.3",
  path: System.find_executable("tailwindcss"),
  pointing_poker: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

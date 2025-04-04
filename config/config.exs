# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Cache,
  # When using :shards as backend
  # backend: :shards,
  # GC interval for pushing new generation: 12 hrs
  gc_interval: :timer.hours(12),
  # Max 1 million entries in cache
  max_size: 1_000_000,
  # Max 2 GB of memory
  allocated_memory: 2_000_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC max timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

config :stream_closed_captioner_phoenix,
  ecto_repos: [StreamClosedCaptionerPhoenix.Repo]

# Configures the endpoint
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "paFgnDds8p/UdoZgGKLX7GV8aP4Yx2yZqUDAGqkicvUoO8yYQZ7gM0oXS0jM7Yg/",
  render_errors: [
    view: StreamClosedCaptionerPhoenixWeb.ErrorHTML,
    accepts: ~w(html json),
    layout: false
  ],
  pubsub_server: StreamClosedCaptionerPhoenix.PubSub,
  live_view: [signing_salt: "gPcQFYTg"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :filter_parameters, [
  "Ocp-Apim-Subscription-Key",
  "current_password",
  "password",
  "secret_key",
  "access_key_id",
  "secret_access_key",
  "secret_key_base",
  "client_id",
  "client_secret",
  "default_signer",
  "token_secret",
  "Authorization",
  ""
]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Guardian,
  issuer: "stream_closed_captioner_phoenix",
  secret_key: "jdWir6loQnsxQ6FEd/AgIHZZmQcZ3hBtmLjSf7czv0IMQdpjtjoMnOkBjat+S1KbbzI=",
  ttl: {3, :days}

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.AuthAccessPipeline,
  module: StreamClosedCaptionerPhoenix.Guardian,
  error_handler: StreamClosedCaptionerPhoenixWeb.AuthErrorHandler

config :kaffy,
  otp_app: :stream_closed_captioner_phoenix,
  ecto_repo: StreamClosedCaptionerPhoenix.Repo,
  router: StreamClosedCaptionerPhoenixWeb.Router,
  scheduled_tasks: [
    StreamClosedCaptionerPhoenix.Settings.StreamSettingsAdmin
  ]

# FunWithFlags configuration
config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: StreamClosedCaptionerPhoenix.Repo,
  ecto_table_name: "fun_with_flags_toggles"

config :fun_with_flags, :cache_bust_notifications, enabled: false

config :ueberauth, Ueberauth,
  providers: [
    identity:
      {Ueberauth.Strategy.Identity,
       [
         callback_methods: ["POST"]
       ]},
    twitch: {Ueberauth.Strategy.Twitch, [default_scope: "user:read:email user:read:broadcast"]}
  ]

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 5, cleanup_interval_ms: 60_000 * 10]}

config :phoenix_meta_tags,
  title: "Stream Closed Captioner",
  description:
    "Easily add Closed Captions to your Twitch stream or Zoom meeting today with just a few clicks of the mouse.",
  url: "https://stream-cc.gooseman.codes",
  image: "/images/cc100x100.png",
  "og:text":
    "Easily add Closed Captions to your Twitch stream or Zoom meeting today with just a few clicks of the mouse."

config :stream_closed_captioner_phoenix, Oban,
  repo: StreamClosedCaptionerPhoenix.Repo,
  plugins: [Oban.Plugins.Pruner, Oban.Plugins.Lifeline, Oban.Plugins.Reindexer],
  queues: [default: 10, events: 10]

config :stream_closed_captioner_phoenix,
  bot: [
    bot: TwitchBot,
    user: "StreamClosedCaptioner",
    pass: System.get_env("TWITCH_CHAT_OAUTH"),
    channels: [],
    debug: false
  ]

config :stream_closed_captioner_phoenix,
  deepgram_token: System.get_env("DEEPGRAM_TOKEN")

config :stream_closed_captioner_phoenix,
  twitch_client_secret: System.get_env("TWITCH_CLIENT_SECRET")

config :stream_closed_captioner_phoenix,
  twitch_client_id: System.get_env("TWITCH_CLIENT_ID")

# Configure the Repo to use advisory locks for locking migrations while running
config StreamClosedCaptionerPhoenix.Repo, migration_lock: :pg_advisory_lock

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :stream_closed_captioner_phoenix,
  twitch_token_secret: System.get_env("TWITCH_TOKEN_SECRET") || ""

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
# Place nothing below this line, CODE SHALL NOT PASS

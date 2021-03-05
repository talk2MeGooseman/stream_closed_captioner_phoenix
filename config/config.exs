# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :stream_closed_captioner_phoenix,
  ecto_repos: [StreamClosedCaptionerPhoenix.Repo]

# Configures the endpoint
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "paFgnDds8p/UdoZgGKLX7GV8aP4Yx2yZqUDAGqkicvUoO8yYQZ7gM0oXS0jM7Yg/",
  render_errors: [view: StreamClosedCaptionerPhoenixWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: StreamClosedCaptionerPhoenix.PubSub,
  live_view: [signing_salt: "gPcQFYTg"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Guardian,
  issuer: "stream_closed_captioner_phoenix",
  secret_key: "jdWir6loQnsxQ6FEd/AgIHZZmQcZ3hBtmLjSf7czv0IMQdpjtjoMnOkBjat+S1KbbzI=",
  ttl: {3, :days}

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.AuthAccessPipeline,
  module: StreamClosedCaptionerPhoenix.Guardian,
  error_handler: StreamClosedCaptionerPhoenixWeb.AuthErrorHandler

config :waffle,
  storage: Waffle.Storage.S3, # or Waffle.Storage.Local
  bucket: System.get_env("AWS_BUCKET_NAME") # if using S3

# If using S3:
config :ex_aws,
  json_codec: Jason,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION")

config :kaffy,
  otp_app: :stream_closed_captioner_phoenix,
  ecto_repo: StreamClosedCaptionerPhoenix.Repo,
  router: StreamClosedCaptionerPhoenixWeb.Router

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Thesis Main Config
config :thesis,
  store: Thesis.EctoStore,
  authorization: StreamClosedCaptionerPhoenix.ThesisAuth,
  uploader: Thesis.RepoUploader

# Thesis Store Config
config :thesis, Thesis.EctoStore, repo: StreamClosedCaptionerPhoenix.Repo

# Thesis Notifications Config
# config :thesis, :notifications,
#   add_page: [],
#   page_settings: [],
#   import_export_restore: []

# Thesis Dynamic Pages Config
config :thesis, :dynamic_pages,
  view: StreamClosedCaptionerPhoenixWeb.PageView,
  templates: ["index.html", "otherview.html"],
  not_found_view: StreamClosedCaptionerPhoenixWeb.ErrorView,
  not_found_template: "404.html"

# FunWithFlags configuration
config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: StreamClosedCaptionerPhoenix.Repo,
  ecto_table_name: "fun_with_flags_toggles"

config :fun_with_flags, :cache_bust_notifications, [enabled: false]

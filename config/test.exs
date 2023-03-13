import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Repo,
  username: "postgres",
  password: "postgres",
  database: "stream_closed_captioner_phoenix_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
  # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
  # !!! From now on, migrations should only be done from Ecto !!!
  migration_source: "ecto_schema_migrations",
  ownership_timeout: 999_999_999

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "paFgnDds8p/UdoZgGKLX7GV8aP4Yx2yZqUDAGqkicvUoO8yYQZ7gM0oXS0jM7Yg/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Mailer,
  adapter: Bamboo.TestAdapter

config :stream_closed_captioner_phoenix, twitch_extension_client: Twitch.MockExtension
config :stream_closed_captioner_phoenix, twitch_helix_client: Twitch.MockHelix
config :stream_closed_captioner_phoenix, azure_cognitive_client: Azure.MockCognitive

config :stream_closed_captioner_phoenix, Oban, testing: :manual

config :stream_closed_captioner_phoenix,
  eventsub_callback_url: "https://localhost:4000"

config :stream_closed_captioner_phoenix,
  twitch_client_secret: "secret"

config :stream_closed_captioner_phoenix,
  twitch_client_id: "client_id"

config :phoenix, :plug_init_mode, :runtime

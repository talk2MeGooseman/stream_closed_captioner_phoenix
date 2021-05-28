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
  # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
  # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
  # !!! From now on, migrations should only be done from Ecto !!!
  migration_source: "ecto_schema_migrations",
  ownership_timeout: 999_999_999

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Mailer,
  adapter: Bamboo.TestAdapter

config :stream_closed_captioner_phoenix, twitch_extension_client: Twitch.MockExtension
config :stream_closed_captioner_phoenix, twitch_helix_client: Twitch.MockHelix
config :stream_closed_captioner_phoenix, azure_cognitive_client: Azure.MockCognitive

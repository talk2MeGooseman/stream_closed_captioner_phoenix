# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url = System.get_env("DATABASE_URL")

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
  # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
  # !!! From now on, migrations should only be done from Ecto !!!
  migration_source: "ecto_schema_migrations"

secret_key_base = System.get_env("SECRET_KEY_BASE")

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
  client_id: System.get_env("TWITCH_CLIENT_ID"),
  client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
  redirect_uri: "http://localhost:4000/auth/twitch/callback"

# config :goth,
#   json: System.get_env("BAMBOO_EMAIL_CREDS")

config :joken, default_signer: System.get_env("TWITCH_TOKEN_SECRET")

config :stream_closed_captioner_phoenix,
  api_key: System.get_env("NOTION_API_KEY"),
  notion_version: System.get_env("NOTION_VERSION")

config :stream_closed_captioner_phoenix,
  eventsub_callback_url: System.get_env("EVENTSUB_CALLBACK_URL")

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

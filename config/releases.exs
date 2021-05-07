# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Repo,
  username: System.get_env("RDS_USERNAME"),
  password: System.get_env("RDS_PASSWORD"),
  database: System.get_env("RDS_DB_NAME"),
  hostname: System.get_env("RDS_HOSTNAME"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
  # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
  # !!! From now on, migrations should only be done from Ecto !!!
  migration_source: "ecto_schema_migrations"

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]],
    compress: true
  ],
  url: [
    scheme: "http",
    host: System.get_env("HOST"),
    port: {:system, "PORT"}
  ],
  secret_key_base: secret_key_base

config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
  client_id: System.get_env("TWITCH_CLIENT_ID"),
  client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
  redirect_uri: System.get_env("TWITCH_REDIRECT_URI")

config :goth,
  json: System.get_env("BAMBOO_EMAIL_CREDS")

config :joken, default_signer: System.get_env("TWITCH_TOKEN_SECRET")

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

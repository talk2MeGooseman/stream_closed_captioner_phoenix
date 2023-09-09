# # In this file, we load production configuration and secrets
# # from environment variables. You can also hardcode secrets,
# # although such is generally not recommended and you have to
# # remember to add this file to your .gitignore.
import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  live_signing_salt =
    System.get_env("LIVE_SIGNING_SALT") ||
      raise """
      environment variable LIVE_SIGNING_SALT is missing.
      You can generate one by calling: mix phx.gen.secret 32
      """

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint,
    # force_ssl: [rewrite_on: [:x_forwarded_proto]]
    server: true,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    # url: [host: System.get_env("HOST"), port: 443, scheme: "https"],
    url: [host: System.get_env("HOST")],
    secret_key_base: secret_key_base,
    live_view: [signing_salt: live_signing_salt]

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Mailer,
    adapter: Bamboo.SendGridAdapter,
    api_key: {:system, "SENDGRID_API_KEY"},
    hackney_opts: [
      recv_timeout: :timer.minutes(1)
    ]

  config :stream_closed_captioner_phoenix, twitch_extension_client: Twitch.Extension
  config :stream_closed_captioner_phoenix, twitch_helix_client: Twitch.Helix
  config :stream_closed_captioner_phoenix, azure_cognitive_client: Azure.Cognitive

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  ecto_ipv6? = System.get_env("ECTO_IPV6") == "true"

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Repo,
    username: System.get_env("RDS_USERNAME"),
    password: System.get_env("RDS_PASSWORD"),
    database: System.get_env("RDS_DB_NAME"),
    hostname: System.get_env("RDS_HOSTNAME"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
    # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
    # !!! From now on, migrations should only be done from Ecto !!!
    migration_source: "ecto_schema_migrations"

  config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
    client_id: System.get_env("TWITCH_CLIENT_ID"),
    client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
    redirect_uri: System.get_env("TWITCH_REDIRECT_URI")

  config :joken, default_signer: System.get_env("TWITCH_TOKEN_SECRET")

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :libcluster,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]

  config :stream_closed_captioner_phoenix,
    api_key: System.get_env("NOTION_API_KEY"),
    notion_version: System.get_env("NOTION_VERSION")

  guardian_secret_key = System.get_env("GUARDIAN_SECRET_KEY")

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Guardian,
    secret_key: guardian_secret_key

  config :stream_closed_captioner_phoenix,
    eventsub_callback_url: System.get_env("EVENTSUB_CALLBACK_URL")
end

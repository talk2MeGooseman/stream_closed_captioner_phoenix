# # In this file, we load production configuration and secrets
# # from environment variables. You can also hardcode secrets,
# # although such is generally not recommended and you have to
# # remember to add this file to your .gitignore.
import Config

config :absinthe_security, AbsintheSecurity.Phase.IntrospectionCheck,
  enable_introspection: System.get_env("GRAPHQL_ENABLE_INTROSPECTION") || true

config :absinthe_security, AbsintheSecurity.Phase.FieldSuggestionsCheck,
  enable_field_suggestions: System.get_env("GRAPHQL_ENABLE_FIELD_SUGGESTIONS") || true

config :absinthe_security, AbsintheSecurity.Phase.MaxAliasesCheck, max_alias_count: 0
config :absinthe_security, AbsintheSecurity.Phase.MaxDepthCheck, max_depth_count: 10
config :absinthe_security, AbsintheSecurity.Phase.MaxDirectivesCheck, max_directive_count: 0

if config_env() == :prod do
  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenixWeb.Endpoint, server: true

  config :stream_closed_captioner_phoenix, twitch_extension_client: Twitch.Extension
  config :stream_closed_captioner_phoenix, twitch_helix_client: Twitch.Helix
  config :stream_closed_captioner_phoenix, azure_cognitive_client: Azure.Cognitive

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: [cacerts: :public_key.cacerts_get()],
    # The App was started from Rails which used the `schema_migrations` table with the same name but different schema
    # To continue with migrations from ecto from now on, we use choose a custom name for the ecto migrations
    # !!! From now on, migrations should only be done from Ecto !!!
    migration_source: "ecto_schema_migrations",
    migration_lock: :pg_advisory_lock

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
    server: true,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    url: [host: System.get_env("HOST"), port: 443, scheme: "https"],
    secret_key_base: secret_key_base,
    live_view: [signing_salt: live_signing_salt]

  config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
    client_id: System.get_env("TWITCH_CLIENT_ID"),
    client_secret: System.get_env("TWITCH_CLIENT_SECRET"),
    redirect_uri: System.get_env("TWITCH_REDIRECT_URI")

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Mailer,
    adapter: Bamboo.SendGridAdapter,
    api_key: {:system, "SENDGRID_API_KEY"},
    hackney_opts: [
      recv_timeout: :timer.minutes(1)
    ],
    sub: "erik.guzman@guzman.codes",
    sandbox: false

  config :joken, default_signer: System.get_env("TWITCH_TOKEN_SECRET")

  # k8s_selector = System.get_env("LIBCLUSTER_KUBERNETES_SELECTOR")
  # k8s_name = System.get_env("LIBCLUSTER_KUBERNETES_NODE_BASENAME")

  # config :libcluster,
  #   topologies: [
  #     k8s_example: [
  #       strategy: Cluster.Strategy.Kubernetes,
  #       config: [
  #         kubernetes_selector: k8s_selector,
  #         kubernetes_node_basename: k8s_name
  #       ]
  #     ]
  #   ]

  config :stream_closed_captioner_phoenix,
    api_key: System.get_env("NOTION_API_KEY"),
    notion_version: System.get_env("NOTION_VERSION")

  guardian_secret_key = System.get_env("GUARDIAN_SECRET_KEY")

  config :stream_closed_captioner_phoenix, StreamClosedCaptionerPhoenix.Guardian,
    secret_key: guardian_secret_key

  config :stream_closed_captioner_phoenix,
    eventsub_callback_url: System.get_env("EVENTSUB_CALLBACK_URL")
end

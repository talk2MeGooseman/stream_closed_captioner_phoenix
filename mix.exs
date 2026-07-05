defmodule StreamClosedCaptionerPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :stream_closed_captioner_phoenix,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:yecc] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {StreamClosedCaptionerPhoenix.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]
  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Absinthe for GraphQL
      {:absinthe, "~> 1.11"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_security, "~> 0.1"},
      {:dataloader, "~> 2.0"},
      # Bamboo for Emailing (upgrade to 2.x in Phase 3b — issue #252)
      {:bamboo, "~> 2.5"},
      {:bypass, "~> 2.1"},
      # Cachex (upgrade to 4.x in Phase 3c — issue #254)
      {:cachex, "~> 4.1"},
      {:cors_plug, "~> 3.0"},
      {:excoveralls, "~> 0.18", only: :test},
      {:circular_buffer, "~> 0.3"},
      {:floki, ">= 0.30.0"},
      {:flop, "~> 0.26"},
      {:flop_phoenix, "~> 0.26"},
      # Other stuff
      {:bcrypt_elixir, "~> 3.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # Add some ecto helpers
      {:ecto_extras, "~> 0.1.3"},
      # For live dashboard
      {:ecto_psql_extras, "~> 0.8"},
      {:ecto_sql, "~> 3.12"},
      {:ex_machina, "~> 2.7.0"},
      # Generate struct from maps
      {:exconstructor, "~> 1.3"},
      # Profanity censoring
      {:expletive, "~> 0.1"},
      {:exsync, "~> 0.2", only: :dev},
      {:fun_with_flags_ui, "~> 1.1.0"},
      {:fun_with_flags, "~> 1.13"},
      # Gettext (upgraded to 1.0 in Phase 3a — issue #253)
      {:gettext, "~> 1.0"},
      {:guardian, "~> 2.4"},
      {:hackney, "~> 1.9"},
      # Rate limiting (upgrade to 7.x in Phase 3d — issue #255)
      {:hammer, "~> 7.3"},
      {:heartcheck, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.6"},
      {:libcluster, "~> 3.5"},
      {:libcluster_ec2, "~> 0.8"},
      {:mock, "~> 0.3", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:mix_test_interactive, "~> 5.1", only: :dev, runtime: false},
      # Cache
      {:nebulex, "~> 2.5"},
      {:decorator, "~> 1.4"},
      # Graphql Client
      {:neuron, "~> 5.0"},
      {:new_relic_agent, "~> 1.40"},
      {:oban, "~> 2.18"},
      {:new_relic_oban, "~> 0.0.1"},
      {:observer_cli, "~> 1.8"},
      {:phoenix_ecto, "~> 4.7"},
      # phoenix_html (upgraded to 4.x in Phase 3f — issue #257)
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8.5"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      # phoenix_live_view (upgraded to 1.x in Phase 3g — issue #259)
      {:phoenix_live_view, "~> 1.1"},
      # Phoenix (upgraded to 1.8 in Phase 3h — issue #258)
      {:phoenix, "~> 1.8"},
      {:plug_cowboy, "~> 2.8"},
      {:poison, "~> 6.0"},
      # postgrex (upgraded in Phase 3f — unblocked by ecto_sql/flop upgrades)
      {:postgrex, "~> 0.19"},
      {:secure_random, "~> 0.5.1"},
      {:sobelow, "~> 0.14", only: :dev},
      {:sweet_xml, "~> 0.7"},
      {:talk_like_a_x, "~> 0.0.8"},
      # telemetry_metrics (upgrade in Phase 3e — issue #256)
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.3"},
      {:ueberauth_twitch, "~> 0.2.0"},
      {:ueberauth, "~> 0.10"},
      {:websockex, "~> 0.5.1"},
      # UI Build stuff
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      # LiveView 1.x test requirement
      {:lazy_html, ">= 0.1.0", only: :test},
      {:jose, "~> 1.11"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        "ecto.setup",
        "cmd npm install --prefix assets",
        "assets.setup",
        "assets.build"
      ],
      "ecto.setup": ["ecto.create", "ecto.load", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        # "tailwind transcript --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      test: ["ecto.create --quiet", "ecto.load --skip-if-loaded", "ecto.migrate --quiet", "test"],
      security: ["sobelow"],
      lint: ["credo"],
      start: ["phx.server"],
      "start.debug": ["iex -S mix phx.server"],
      routes: ["phx.routes"]
    ]
  end
end

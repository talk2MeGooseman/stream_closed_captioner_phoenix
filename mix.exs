defmodule StreamClosedCaptionerPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :stream_closed_captioner_phoenix,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
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
      {:absinthe, "~> 1.7"},
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_cache, git: "https://github.com/IvanIvanoff/absinthe_cache", branch: "master"},
      # Disable GQL introspection
      {:vigil, "~> 0.4.4"},
      # Bamboo for Emailing
      {:bamboo, "~> 1.7.1"},
      {:bypass, "~> 2.1.0"},
      {:cachex, "~> 3.4"},
      {:cors_plug, "~> 3.0"},
      {:circular_buffer, "~> 0.3"},
      {:premailex, "~> 0.3.0"},
      {:floki, ">= 0.30.0"},
      {:flop, "~> 0.22.1"},
      {:flop_phoenix, "~> 0.21.1"},
      # Waffle for file upload
      {:waffle, "~> 1.1.1"},
      {:waffle_ecto, "~> 0.0.9"},
      # If using Waffle with S3:
      {:ex_aws, "~> 2.4"},
      # Other stuff
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      # Add some ecto helpers
      {:ecto_extras, "~> 0.1.3"},
      # For live dashboard
      {:ecto_psql_extras, "~> 0.2"},
      {:ecto_sql, "~> 3.4"},
      {:ex_machina, "~> 2.7.0"},
      # Generate struct from maps
      {:exconstructor, "~> 1.1"},
      # Profanity censoring
      {:expletive, "~> 0.1.4"},
      {:exsync, "~> 0.2", only: :dev},
      {:fun_with_flags_ui, "~> 0.8.1"},
      {:fun_with_flags, "~> 1.10"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:hackney, "~> 1.9"},
      # Rate limiting
      {:hammer, "~> 6.0"},
      {:heartcheck, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.3"},
      # Admin Dashboard
      {:kaffy, "0.10.2"},
      {:libcluster, "~> 3.3"},
      {:libcluster_ec2, "~> 0.7"},
      {:mox, "~> 1.0.0"},
      {:mix_test_interactive, "~> 1.0", only: :dev, runtime: false},
      # Cache
      {:nebulex, "~> 2.5"},
      {:decorator, "~> 1.4"},
      # Graphql Client
      {:neuron, "~> 5.0"},
      {:new_relic_agent, "~> 1.27"},
      {:new_relic_absinthe, "~> 0.0.4"},
      {:oban, "~> 2.13"},
      {:new_relic_oban, "~> 0.0.1"},
      {:observer_cli, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.0"},
      {:phoenix_view, "~> 2.0.2"},
      {:phoenix, "~> 1.7.7"},
      {:phoenix_meta_tags, "~> 0.1.9"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 5.0"},
      {:postgrex, ">= 0.0.0"},
      {:secure_random, "~> 0.5.1"},
      {:sobelow, "~> 0.11", only: :dev},
      {:sweet_xml, "~> 0.6"},
      {:talk_like_a_x, "~> 0.0.8"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:tmi, "~> 0.5.3"},
      {:ueberauth_twitch, "~> 0.1.0"},
      {:ueberauth, "~> 0.10"},
      {:websockex, "~> 0.4.3"},
      # UI Build stuff
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev}
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
        "tailwind transcript --minify",
        "esbuild default --minify",
        "phx.digest"
      ],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      security: ["sobelow"],
      lint: ["credo"],
      start: ["phx.server"],
      "start.debug": ["iex -S mix phx.server"],
      routes: ["phx.routes"]
    ]
  end
end

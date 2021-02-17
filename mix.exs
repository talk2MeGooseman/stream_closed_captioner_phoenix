defmodule StreamClosedCaptionerPhoenix.MixProject do
  use Mix.Project
  def project do
    [
      app: :stream_closed_captioner_phoenix,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      extra_applications: [:logger, :runtime_tools]
    ]
  end
  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Absinthe for GraphQL
      {:absinthe, "~> 1.5.0"},
      {:absinthe_plug, "~> 1.5.0"},

      # Bamboo for Emailing
      {:bamboo, "~> 1.5"},
      {:premailex, "~> 0.3.0"},
      {:floki, ">= 0.0.0"},

      # Waffle for file upload
      {:waffle, "~> 1.1.1"},
      {:waffle_ecto, "~> 0.0.9"},
      # If using Waffle with S3:
      {:ex_aws, "~> 2.1.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:guardian, "~> 2.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:phx_gen_auth, "~> 0.6", only: [:dev], runtime: false},
      {:sobelow, "~> 0.8", only: :dev},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.5.7"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"}
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
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.load", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.load", "ecto.migrate --quiet", "test"],
      security: ["sobelow"],
      lint: ["credo"],
      start: ["phx.server"],
      "start.debug": ["iex -S mix phx.server"]
    ]
  end
end

defmodule StreamClosedCaptionerPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # start libcluster
      {Cluster.Supervisor, [topologies, [name: StreamClosedCaptionerPhoenix.ClusterSupervisor]]},
      # Start the Ecto repository
      StreamClosedCaptionerPhoenix.Repo,
      # Start the Telemetry supervisor
      StreamClosedCaptionerPhoenixWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: StreamClosedCaptionerPhoenix.PubSub},
      # Start the Endpoint (http/https)
      StreamClosedCaptionerPhoenixWeb.Endpoint,
      # Start a worker by calling: StreamClosedCaptionerPhoenix.Worker.start_link(arg)
      # {StreamClosedCaptionerPhoenix.Worker, arg}
      StreamClosedCaptionerPhoenixWeb.ActivePresence,
      StreamClosedCaptionerPhoenix.TranslationCache,
      {Absinthe.Subscription, StreamClosedCaptionerPhoenixWeb.Endpoint},
      {ConCache,
       [
         name: :graphql_cache,
         ttl_check_interval: :timer.seconds(30),
         global_ttl: :timer.minutes(1),
         acquire_lock_timeout: 30_000
       ]},
      {TMI.Supervisor, bot_config()},
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StreamClosedCaptionerPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StreamClosedCaptionerPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Conditionally disable queues or plugins here.
  defp oban_config do
    Application.fetch_env!(:stream_closed_captioner_phoenix, Oban)
  end

  defp bot_config do
    Application.fetch_env!(:stream_closed_captioner_phoenix, :bot)
  end
end

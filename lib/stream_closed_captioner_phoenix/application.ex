defmodule StreamClosedCaptionerPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # List all child processes to be supervised
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # start libcluster
      {Cluster.Supervisor, [topologies, [name: StreamClosedCaptionerPhoenix.ClusterSupervisor]]},
      # Start the Ecto repository
      StreamClosedCaptionerPhoenix.Repo,
      # Supervised Finch pool used by Req across all external service adapters
      # (5s TCP connect timeout, matching the previous hackney default).
      {Finch,
       name: StreamClosedCaptionerPhoenix.Finch,
       pools: %{default: [conn_opts: [transport_opts: [timeout: 5_000]]]}},
      # Start the Telemetry supervisor
      StreamClosedCaptionerPhoenixWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: StreamClosedCaptionerPhoenix.PubSub},
      # Start the Endpoint (http/https)
      StreamClosedCaptionerPhoenixWeb.Endpoint,
      # Start a worker by calling: StreamClosedCaptionerPhoenix.Worker.start_link(arg)
      # {StreamClosedCaptionerPhoenix.Worker, arg}
      {StreamClosedCaptionerPhoenixWeb.UserTracker,
       [
         name: StreamClosedCaptionerPhoenixWeb.UserTracker,
         pubsub_server: StreamClosedCaptionerPhoenix.PubSub
       ]},
      {Absinthe.Subscription, StreamClosedCaptionerPhoenixWeb.Endpoint},
      {StreamClosedCaptionerPhoenix.Cache, []},
      {StreamClosedCaptionerPhoenix.RateLimit, [clean_period: 600_000]},
      NewRelicOban.Telemetry.Oban,
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StreamClosedCaptionerPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StreamClosedCaptionerPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Conditionally disable queues or plugins here.
  defp oban_config do
    Application.fetch_env!(:stream_closed_captioner_phoenix, Oban)
  end
end

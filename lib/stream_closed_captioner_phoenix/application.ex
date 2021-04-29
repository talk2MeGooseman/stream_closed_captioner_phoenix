defmodule StreamClosedCaptionerPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
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
      StreamClosedCaptionerPhoenixWeb.ActivePresence
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
end

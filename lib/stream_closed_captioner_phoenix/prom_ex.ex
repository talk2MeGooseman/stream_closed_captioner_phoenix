defmodule StreamClosedCaptionerPhoenix.PromEx do
  @moduledoc """
  PromEx supervisor for the captions app.

  Plugins:
  - `PromEx.Plugins.Application` — basic app info
  - `PromEx.Plugins.Beam` — BEAM VM metrics
  - `PromEx.Plugins.Phoenix` — Phoenix endpoint/router metrics
  - `PromEx.Plugins.Ecto` — Ecto query timings
  - `Observability.PromExPlugin` — caption-flow events

  PromEx.Plugins.Oban is intentionally omitted (out of scope).
  """

  use PromEx, otp_app: :stream_closed_captioner_phoenix

  alias PromEx.Plugins
  alias StreamClosedCaptionerPhoenix.Observability

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix,
       router: StreamClosedCaptionerPhoenixWeb.Router,
       endpoint: StreamClosedCaptionerPhoenixWeb.Endpoint},
      Plugins.Ecto,
      Observability.PromExPlugin
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"},
      {:stream_closed_captioner_phoenix, "captions_overview.json"},
      {:stream_closed_captioner_phoenix, "captions_latency.json"}
    ]
  end

  @impl true
  def dashboard_assigns do
    [datasource_id: "prometheus", default_selected_interval: "30s"]
  end
end

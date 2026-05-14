defmodule StreamClosedCaptionerPhoenixWeb.Telemetry do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    StreamClosedCaptionerPhoenix.Observability.Metrics.metrics()
  end

  defp periodic_measurements do
    []
  end
end

defmodule StreamClosedCaptionerPhoenixWeb.Plugs.MetricsAuth do
  @moduledoc """
  Bearer-token gate for the `/metrics` endpoint scraped by Prometheus.

  Returns 401 (empty body) on missing/wrong token.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.fetch_env!(:stream_closed_captioner_phoenix, :metrics_auth_token)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(token, expected) do
      conn
    else
      _ ->
        conn |> send_resp(401, "") |> halt()
    end
  end
end

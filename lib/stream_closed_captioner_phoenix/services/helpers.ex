defmodule Helpers do
  @moduledoc false

  # Supervised Finch pool (started in StreamClosedCaptionerPhoenix.Application) so
  # Req reuses connections/TLS sessions instead of starting a cold pool per caller.
  @req_finch StreamClosedCaptionerPhoenix.Finch

  # Note: `connect_options` cannot be combined with a named `:finch` pool — the
  # connect timeout is configured on the Finch pool itself (see Application).
  @default_req_options [
    finch: @req_finch,
    retry: false,
    decode_body: false,
    receive_timeout: 10_000
  ]

  @doc """
  Shared `Req` options for every external service adapter.

  Defaults: the supervised `Finch` pool, no automatic retries (matching the
  previous HTTPoison behaviour), raw string bodies (`decode_body: false`, so
  callers keep doing their own JSON decoding), and connect/receive timeouts.

  Pass `overrides` to tune a call site — e.g. a shorter `receive_timeout` on the
  translation hot path, where the caller already imposes a 3s task budget.
  """
  @spec req_options(keyword()) :: keyword()
  def req_options(overrides \\ []), do: Keyword.merge(@default_req_options, overrides)

  @spec encode_url_and_params(binary | URI.t(), map() | list()) :: binary
  def encode_url_and_params(url, params \\ %{}) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end
end

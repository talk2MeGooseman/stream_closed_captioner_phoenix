defmodule Twitch.Parser do
  @moduledoc """
  Generic parser that normalises an HTTP response into a tagged tuple.

  Matches on a plain map (`%{status: ..., body: ...}`) rather than a specific
  HTTP client's response struct, so it stays decoupled from the underlying
  library (works with `%Req.Response{}` or any map-shaped response).
  """

  @type status_code :: integer
  @type headers :: map
  @type response ::
          {:ok, term()}
          | {:error, term()}
          | {:error, term(), status_code()}
          | term()

  @doc """
  Parses the response from API calls
  """
  @spec parse(term()) :: response
  def parse({:ok, %{status: status, body: body}}) when status in [200, 201],
    do: decode_body(body)

  def parse({:error, %{reason: reason}}), do: {:error, %{reason: reason}}

  def parse({:ok, %{status: status, body: body}}), do: error_with_status(body, status)

  def parse(response), do: response

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:json_decode, reason}}
    end
  end

  defp error_with_status(body, status) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:error, decoded, status}
      {:error, _reason} -> {:error, body, status}
    end
  end
end

defmodule Helpers do
  @spec encode_url_and_params(binary | URI.t(), map() | list()) :: binary
  def encode_url_and_params(url, params \\ %{}) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end
end

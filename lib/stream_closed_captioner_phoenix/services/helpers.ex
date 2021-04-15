defmodule Helpers do
  @spec encode_url_and_params(binary | URI.t(), map() | list()) :: binary
  def encode_url_and_params(url, params \\ %{}) do
    url
    |> URI.parse()
    |> merge_params(params)
    |> URI.to_string()
  end

  defp merge_params(uri, params) do
    encoded_params =
      Map.get(uri, :query) ||
        %{}
        |> Map.merge(params)
        |> URI.encode_query()

    Map.put(uri, :query, encoded_params)
  end
end

defmodule Notion.Base do
  @moduledoc false
  alias NewRelic.Instrumented.HTTPoison

  alias Notion.Parser
  import Notion.Utils

  @base_url "https://api.notion.com/v1"

  def get(path_arg, query_params \\ %{}) do
    path_arg
    |> build_url(query_params)
    |> HTTPoison.get(request_headers())
    |> Parser.parse()
  end

  def post(path_arg, body \\ %{}) do
    json_body = Jason.encode!(body)

    path_arg
    |> build_url()
    |> HTTPoison.post(json_body, post_request_headers())
    |> Parser.parse()
  end

  defp build_url(path_arg, query_params \\ %{}) do
    query_params = process_params(query_params)

    "#{@base_url}/#{path_arg}?#{URI.encode_query(query_params)}"
  end

  def process_params(params) do
    %{}
    |> Map.merge(params)
    |> Map.delete(:__struct__)
  end
end

defmodule Notion.Parser do
  @moduledoc """
  Generic parser to parse api response
  """

  @type status_code :: integer
  @type headers :: map
  @type response ::
          {:ok, term()}
          | {:error, map()}
          | {:error, term(), status_code()}
          | term()

  @doc """
  Parses the response from API calls
  """
  @spec parse(tuple) :: response
  def parse({:ok, %Req.Response{body: body, status: status}})
      when status in [200, 201],
      do: {:ok, parse_response_body(body)}

  def parse({:error, %{reason: reason}}), do: {:error, %{reason: reason}}

  def parse({:ok, %Req.Response{body: body, status: status}}),
    do: {:error, parse_response_body(body), status}

  def parse(response), do: response

  defp parse_response_body(body), do: Poison.decode!(body)
end

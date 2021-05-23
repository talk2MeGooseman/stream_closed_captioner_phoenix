defmodule Notion.Database do
  @moduledoc """
  Simple API wrapper for Notion API
  """
  import Notion.Base

  @doc """
  Retrieves a Database object using the ID specified.

  Errors
  Returns a 404 HTTP response if the database doesn't exist, or if the integration doesn't have access to the database.
  Returns a 400 or 429 HTTP response if the request exceeds the request limits.
  """
  def retrieve_database(database_id), do: get("databases/#{database_id}")

  @doc """
  Gets a list of Pages contained in the database, filtered and ordered according to the filter conditions and sort criteria provided in the request. The response may contain fewer than page_size of results.

  Filters are similar to the filters provided in the Notion UI. Filters operate on database properties and can be combined. If no filter is provided, all the pages in the database will be returned with pagination.

  Sorts are similar to the sorts provided in the Notion UI. Sorts operate on database properties or page timestamps and can be combined. The order of the sorts in the request matter, with earlier sorts taking precedence over later ones.

  Notion.Database.query_database("8f9f6076e708455fbb263b3ba9ca48db", %{ sorts: [%{ property: "Published", direction: "descending" }]})

  iex> {:ok,
    %{
      "has_more" => false,
      "next_cursor" => nil,
      "object" => "list",
      "results" => [
        %{
          "archived" => false,
          "created_time" => "2021-05-22T06:15:42.036Z",
          "id" => "08f40d1e-9a9b-48e7-9da2-0e2362f5e372",
          "last_edited_time" => "2021-05-22T18:09:00.000Z",
          "object" => "page",
          "parent" => %{
            "database_id" => "8f9f6076-e708-455f-bb26-3b3ba9ca48db",
            "type" => "database_id"
          },
          "properties" => %{
            "Name" => %{
              "id" => "title",
              "title" => [
                %{
                  "annotations" => %{
                    "bold" => false,
                    "code" => false,
                    "color" => "default",
                    "italic" => false,
                    "strikethrough" => false,
                    "underline" => false
                  },
                  "href" => nil,
                  "plain_text" => "New Article",
                  "text" => %{"content" => "New Article", "link" => nil},
                  "type" => "text"
                }
              ],
              "type" => "title"
            },
            "Published" => %{
              "date" => %{"end" => nil, "start" => "2021-05-23"},
              "id" => "e_M=",
              "type" => "date"
            }
          }
        }
      ]
    }}
  """
  def query_database(database_id, body \\ %{}), do: post("databases/#{database_id}/query", body)
end

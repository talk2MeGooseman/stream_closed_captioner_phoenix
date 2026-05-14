defmodule StreamClosedCaptionerPhoenixWeb.AnnouncementsControllerTest do
  use StreamClosedCaptionerPhoenixWeb.ConnCase, async: false

  import Mox

  alias StreamClosedCaptionerPhoenix.Cache

  @cache_key :notion_announcements_pages
  @notion_db_id "8f9f6076e708455fbb263b3ba9ca48db"

  setup :verify_on_exit!

  setup do
    Cache.delete(@cache_key)
    :ok
  end

  describe "GET /announcements" do
    test "renders the announcements page with pages returned from Notion", %{conn: conn} do
      pages = [
        %{
          "id" => "abc-123",
          "properties" => %{
            "Name" => %{"title" => [%{"plain_text" => "My Announcement"}]},
            "Published" => %{"date" => %{"start" => "2024-01-15"}},
            "tldr" => %{"rich_text" => [%{"plain_text" => "A short summary"}]}
          }
        }
      ]

      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages}}
      end)

      conn = get(conn, ~p"/announcements")

      assert conn.status == 200
      assert conn.resp_body =~ "My Announcement"
    end

    test "renders the announcements page with an empty list when Notion fails", %{conn: conn} do
      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:error, :timeout}
      end)

      conn = get(conn, ~p"/announcements")

      assert conn.status == 200
      assert conn.resp_body =~ "Annoucements and News"
    end

    test "does not hit Notion on a second request within the cache TTL", %{conn: conn} do
      pages = [
        %{
          "id" => "xyz-456",
          "properties" => %{
            "Name" => %{"title" => [%{"plain_text" => "Cached Post"}]},
            "Published" => %{"date" => %{"start" => "2024-02-01"}},
            "tldr" => %{"rich_text" => [%{"plain_text" => "Cached summary"}]}
          }
        }
      ]

      # Notion is called exactly once; the second request is served from cache
      Notion.MockDatabase
      |> expect(:query_database, 1, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages}}
      end)

      conn1 = get(conn, ~p"/announcements")
      assert conn1.status == 200

      conn2 = get(conn, ~p"/announcements")
      assert conn2.status == 200
      assert conn2.resp_body =~ "Cached Post"
    end
  end
end

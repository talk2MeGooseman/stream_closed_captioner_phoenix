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

  defp page(id, name, published) do
    %{
      "id" => id,
      "properties" => %{
        "Name" => %{"title" => [%{"plain_text" => name}]},
        "Published" => %{"date" => %{"start" => published}},
        "tldr" => %{"rich_text" => [%{"plain_text" => "summary"}]}
      }
    }
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
      # timeline entry: title links to Notion, date formatted on the rail
      assert conn.resp_body =~ "My Announcement"
      assert conn.resp_body =~ "Jan 15, 2024"
      assert conn.resp_body =~ "A short summary"
      assert conn.resp_body =~ "Continue reading"
    end

    test "renders the changelog header and empty state when Notion fails", %{conn: conn} do
      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:error, :timeout}
      end)

      conn = get(conn, ~p"/announcements")

      assert conn.status == 200
      # new design header + graceful empty state (no entries to show)
      assert conn.resp_body =~ "Changelog"
      assert conn.resp_body =~ "No announcements yet"
    end

    test "renders the shared Stream CC nav and footer chrome", %{conn: conn} do
      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => []}}
      end)

      html = conn |> get(~p"/announcements") |> html_response(200)

      # nav highlights Announcements; CTA + footer come from the :scc layout
      assert html =~ "aria-current=\"page\""
      assert html =~ "Connect with Twitch"
      assert html =~ "Erik Guzman"
      # the old shared header must NOT also render (no doubled nav)
      refute html =~ "darkmode#toggle"
    end

    test "orders the timeline newest-first regardless of Notion's order", %{conn: conn} do
      pages = [
        page("older", "Older Post", "2024-01-01"),
        page("newer", "Newer Post", "2024-03-01")
      ]

      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages}}
      end)

      body = conn |> get(~p"/announcements") |> html_response(200)

      assert :binary.match(body, "Newer Post") < :binary.match(body, "Older Post")
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

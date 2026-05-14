defmodule StreamClosedCaptionerPhoenix.AnnouncementsTest do
  use ExUnit.Case, async: false

  import Mox

  alias StreamClosedCaptionerPhoenix.Announcements
  alias StreamClosedCaptionerPhoenix.Cache

  @cache_key :notion_announcements_pages
  @notion_db_id "8f9f6076e708455fbb263b3ba9ca48db"

  setup :verify_on_exit!

  setup do
    Cache.delete(@cache_key)
    :ok
  end

  describe "list_announcement_pages/0" do
    test "calls Notion and returns the results list on success" do
      pages = [%{"id" => "page-1"}, %{"id" => "page-2"}]

      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages}}
      end)

      assert Announcements.list_announcement_pages() == pages
    end

    test "returns empty list when Notion returns an error" do
      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:error, :timeout}
      end)

      assert Announcements.list_announcement_pages() == []
    end

    test "returns empty list when Notion response has no 'results' key" do
      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{}}
      end)

      assert Announcements.list_announcement_pages() == []
    end

    test "caches results so Notion is only called once across repeated requests" do
      pages = [%{"id" => "cached-page"}]

      # expect exactly 1 call — second invocation must come from cache
      Notion.MockDatabase
      |> expect(:query_database, 1, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages}}
      end)

      assert Announcements.list_announcement_pages() == pages
      assert Announcements.list_announcement_pages() == pages
    end

    test "calls Notion again when the cache has been cleared" do
      pages_first = [%{"id" => "first"}]
      pages_second = [%{"id" => "second"}]

      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages_first}}
      end)

      assert Announcements.list_announcement_pages() == pages_first

      Cache.delete(@cache_key)

      Notion.MockDatabase
      |> expect(:query_database, fn @notion_db_id, %{} ->
        {:ok, %{"results" => pages_second}}
      end)

      assert Announcements.list_announcement_pages() == pages_second
    end

    test "does not cache empty results from a Notion error (allows retry on next request)" do
      Notion.MockDatabase
      |> expect(:query_database, 2, fn @notion_db_id, %{} ->
        {:error, :unavailable}
      end)

      assert Announcements.list_announcement_pages() == []
      assert Announcements.list_announcement_pages() == []
    end

    test "does not cache an empty results list from a successful Notion response (allows retry on next request)" do
      # Notion responds OK but with zero pages — e.g. the DB is temporarily empty.
      # Two consecutive calls must both reach Notion; the empty list must not be
      # written to cache, because on the next publish the page would stay blank
      # until the TTL expires.
      Notion.MockDatabase
      |> expect(:query_database, 2, fn @notion_db_id, %{} ->
        {:ok, %{"results" => []}}
      end)

      assert Announcements.list_announcement_pages() == []
      assert Announcements.list_announcement_pages() == []
    end
  end
end

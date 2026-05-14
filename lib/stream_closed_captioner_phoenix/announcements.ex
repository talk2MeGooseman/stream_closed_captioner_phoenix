defmodule StreamClosedCaptionerPhoenix.Announcements do
  @moduledoc """
  Context for Notion-backed announcement pages.

  Results are cached for a short TTL so that repeated page renders do not hit
  the Notion API on every request. Errors and empty responses are never cached
  so that a transient Notion outage does not lock the page into a stale empty
  state across the full TTL window.
  """

  alias StreamClosedCaptionerPhoenix.Cache

  @notion_db_id "8f9f6076e708455fbb263b3ba9ca48db"
  @cache_key :notion_announcements_pages
  @cache_ttl :timer.minutes(5)

  @doc """
  Returns the list of announcement pages from the Notion database.

  Results are served from cache when available. On a cache miss the Notion API
  is queried; successful results are stored with a #{div(@cache_ttl, 60_000)}-minute
  TTL. If Notion returns an error or no `"results"` key, an empty list is
  returned and nothing is written to cache (so the next request will retry).
  """
  @spec list_announcement_pages() :: list(map())
  def list_announcement_pages do
    case Cache.get(@cache_key) do
      nil -> fetch_and_cache()
      pages -> pages
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp fetch_and_cache do
    case notion_client().query_database(@notion_db_id, %{}) do
      {:ok, %{"results" => [_ | _] = pages}} ->
        Cache.put(@cache_key, pages, ttl: @cache_ttl)
        pages

      {:ok, _} ->
        []

      _error ->
        []
    end
  end

  defp notion_client do
    Application.get_env(
      :stream_closed_captioner_phoenix,
      :notion_database_client,
      Notion.Database
    )
  end
end

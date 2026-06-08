defmodule StreamClosedCaptionerPhoenixWeb.AnnouncementsHTML do
  use StreamClosedCaptionerPhoenixWeb, :html

  embed_templates("announcements/*")

  @notion_base "https://www.notion.so/talk2megooseman/"
  @months ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  @doc """
  Announcements ordered newest-first by published date for the timeline feed.

  ISO 8601 date strings sort chronologically as plain strings; undated pages
  fall to the end.
  """
  def sorted_pages(pages), do: Enum.sort_by(pages, &date_key/1, :desc)

  @doc "Link to the Notion page for an announcement (id with dashes stripped)."
  def notion_url(page) do
    id = page |> get_in(["id"]) |> to_string() |> String.replace("-", "")
    @notion_base <> id
  end

  @doc "Announcement title (Notion `Name`) as plain text, or an empty string."
  def page_title(page), do: plain_text(get_in(page, ["properties", "Name", "title"]))

  @doc "Announcement TL;DR (Notion `tldr`) as plain text, or an empty string."
  def page_tldr(page), do: plain_text(get_in(page, ["properties", "tldr", "rich_text"]))

  @doc "Raw published date (ISO 8601 string) from Notion, or nil."
  def page_date(page), do: get_in(page, ["properties", "Published", "date", "start"])

  @doc ~S"""
  Formats a Notion date such as `"2026-05-28"` (or a full ISO datetime) as
  `"May 28, 2026"`. Returns an empty string for nil or unparseable input.
  """
  def format_date(nil), do: ""

  def format_date(iso) when is_binary(iso) do
    case Date.from_iso8601(String.slice(iso, 0, 10)) do
      {:ok, %Date{year: y, month: m, day: d}} -> "#{Enum.at(@months, m - 1)} #{d}, #{y}"
      _ -> ""
    end
  end

  def format_date(_), do: ""

  # Notion title/rich_text fields are arrays of segments; concatenate the
  # `plain_text` of each so multi-segment values render in full.
  defp plain_text(segments) when is_list(segments) do
    Enum.map_join(segments, "", &Map.get(&1, "plain_text", ""))
  end

  defp plain_text(_), do: ""

  # Sort key: the YYYY-MM-DD prefix of the published date, or "" when missing
  # (which sorts last under :desc).
  defp date_key(page) do
    case page_date(page) do
      iso when is_binary(iso) -> String.slice(iso, 0, 10)
      _ -> ""
    end
  end
end

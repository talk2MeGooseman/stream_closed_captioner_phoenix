defmodule StreamClosedCaptionerPhoenixWeb.MetaTags do
  @moduledoc """
  Inline replacement for phoenix_meta_tags (not compatible with phoenix_html 4.x).
  Renders standard, Open Graph, and Twitter meta tags from a flat/nested map.
  """

  import PhoenixHTMLHelpers.Tag

  @default_tags [
    "title",
    "description",
    "image",
    "url",
    "og:type",
    "og:url",
    "og:title",
    "og:description",
    "og:image",
    "twitter:title",
    "twitter:card",
    "twitter:url",
    "twitter:description",
    "twitter:image"
  ]

  @config %{}

  defp flatten_entry(prefix, key, value) when is_map(value) do
    p = build_prefix(prefix, key)
    Enum.flat_map(value, fn {k, v} -> flatten_entry(p, k, v) end)
  end

  defp flatten_entry(prefix, key, value), do: [%{build_prefix(prefix, key) => value}]

  defp build_prefix("", key), do: to_string(key)
  defp build_prefix(prefix, key), do: prefix <> ":" <> to_string(key)

  defp flatten(map) do
    map
    |> Enum.flat_map(fn {k, v} -> flatten_entry("", k, v) end)
    |> Enum.reduce(%{}, &Map.merge(&2, &1))
  end

  defp get_value(tags, item), do: tags[item] || @config[item]

  defp get_tags_value(tags, default_key, key),
    do: tags[key] || tags[default_key] || @config[default_key]

  def render_tag_default(tags) do
    [
      content_tag(:title, get_value(tags, "title")),
      tag(:meta, content: get_value(tags, "title"), name: "title"),
      tag(:meta, content: get_value(tags, "description"), name: "description")
    ]
  end

  def render_tag_og(tags) do
    [
      tag(:meta, content: get_tags_value(tags, "og:type", "og:type"), property: "og:type"),
      tag(:meta, content: get_tags_value(tags, "url", "og:url"), property: "og:url"),
      tag(:meta, content: get_tags_value(tags, "title", "og:title"), property: "og:title"),
      tag(:meta,
        content: get_tags_value(tags, "description", "og:description"),
        property: "og:description"
      ),
      tag(:meta, content: get_tags_value(tags, "image", "og:image"), property: "og:image")
    ]
  end

  def render_tag_twitter(tags) do
    [
      tag(:meta,
        content: get_tags_value(tags, "twitter:card", "twitter:card"),
        name: "twitter:card"
      ),
      tag(:meta, content: get_tags_value(tags, "url", "twitter:url"), name: "twitter:url"),
      tag(:meta,
        content: get_tags_value(tags, "title", "twitter:title"),
        name: "twitter:title"
      ),
      tag(:meta,
        content: get_tags_value(tags, "description", "twitter:description"),
        name: "twitter:description"
      ),
      tag(:meta,
        content: get_tags_value(tags, "image", "twitter:image"),
        name: "twitter:image"
      )
    ]
  end

  defp render_tags_map(map) do
    Enum.map(map, fn
      {"twitter:" <> _ = k, v} -> tag(:meta, content: v, name: k)
      {k, v} -> tag(:meta, content: v, property: k)
    end)
  end

  @doc "Renders all meta tags: default, Open Graph, and Twitter."
  def render_tags_all(tags) do
    ntags = flatten(tags)
    new_tags = Map.merge(@config, ntags)
    other_tags = Map.drop(new_tags, @default_tags)

    render_tag_default(new_tags) ++
      render_tag_og(new_tags) ++
      render_tag_twitter(new_tags) ++
      render_tags_map(other_tags)
  end
end

defmodule Notion.Page do
  @moduledoc """
  Simple API wrapper for Notion API
  """
  import Notion.Base

  @doc """
  Notion.Page.retrieve_page("08f40d1e-9a9b-48e7-9da2-0e2362f5e372")
  """
  def retrieve_page(page_id), do: get("pages/#{page_id}")
  defdelegate retrieve_block_children(block_id, params \\ %{}), to: Notion.Block
end

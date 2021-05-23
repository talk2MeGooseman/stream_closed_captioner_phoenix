defmodule Notion.Block do
  @moduledoc """
  Simple API wrapper for Notion API
  """
  import Notion.Base

  @doc """
  """
  def retrieve_block_children(page_id, params),
    do: get("blocks/#{page_id}/children", params)
end

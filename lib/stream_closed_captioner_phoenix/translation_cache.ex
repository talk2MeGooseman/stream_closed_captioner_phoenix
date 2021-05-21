defmodule StreamClosedCaptionerPhoenix.TranslationCache do
  @moduledoc """
  Translation Cache
  """
  @cache_table :translation_cache
  def child_spec(_init_arg) do
    %{
      id: @cache_table,
      type: :supervisor,
      start: {Cachex, :start_link, [@cache_table, []]}
    }
  end
end

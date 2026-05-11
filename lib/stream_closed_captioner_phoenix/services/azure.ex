defmodule Azure do
  use Nebulex.Caching

  def api_client,
    do: Application.get_env(:stream_closed_captioner_phoenix, :azure_cognitive_client)

  @spec perform_translations(String.t(), [String.t()], String.t()) ::
          {:ok, Azure.Cognitive.Translations.t()} | {:error, term()}
  def perform_translations(from_language, to_languages, text) do
    metadata = %{
      from_lang: from_language,
      to_count: length(to_languages),
      result: nil,
      http_status: nil,
      error_reason: nil
    }

    :telemetry.span([:scc, :outbound, :azure_translation], metadata, fn ->
      case api_client().translate(from_language, to_languages, text) do
        {:ok, _} = ok -> {ok, %{metadata | result: :ok}}
        {:error, reason} = err -> {err, %{metadata | result: :error, error_reason: inspect(reason)}}
      end
    end)
  end
end

defmodule StreamClosedCaptionerPhoenix.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Settings.StreamSettings

  @doc """
  Returns the list of stream_settings.

  ## Examples

      iex> list_stream_settings()
      [%StreamSettings{}, ...]

  """
  def list_stream_settings do
    Repo.all(StreamSettings)
  end

  @doc """
  Gets a single stream_settings.

  Raises `Ecto.NoResultsError` if the Stream settings does not exist.

  ## Examples

      iex> get_stream_settings!(123)
      %StreamSettings{}

      iex> get_stream_settings!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stream_settings!(id), do: Repo.get!(StreamSettings, id)

  @doc """
  Gets a single stream_setting by user id.

  Raises `Ecto.NoResultsError` if the Stream settings does not exist.

  ## Examples

      iex> get_stream_settings_by_user_id!(123)
      %StreamSettings{}

      iex> get_stream_settings_by_user_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stream_settings_by_user_id!(id),
    do: Repo.get_by!(StreamSettings, user_id: id)

  @doc """
  Creates a stream_settings.

  ## Examples

      iex> create_stream_settings(%{field: value})
      {:ok, %StreamSettings{}}

      iex> create_stream_settings(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stream_settings(attrs \\ %{}) do
    %StreamSettings{}
    |> StreamSettings.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stream_settings.

  ## Examples

      iex> update_stream_settings(stream_settings, %{field: new_value})
      {:ok, %StreamSettings{}}

      iex> update_stream_settings(stream_settings, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stream_settings(%StreamSettings{} = stream_settings, attrs) do
    stream_settings
    |> StreamSettings.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stream_settings.

  ## Examples

      iex> delete_stream_settings(stream_settings)
      {:ok, %StreamSettings{}}

      iex> delete_stream_settings(stream_settings)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stream_settings(%StreamSettings{} = stream_settings) do
    Repo.delete(stream_settings)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stream_settings changes.

  ## Examples

      iex> change_stream_settings(stream_settings)
      %Ecto.Changeset{data: %StreamSettings{}}

  """
  def change_stream_settings(%StreamSettings{} = stream_settings, attrs \\ %{}) do
    StreamSettings.changeset(stream_settings, attrs)
  end

  alias StreamClosedCaptionerPhoenix.Settings.TranslateLanguages

  @doc """
  Returns the list of translate_languages.

  ## Examples

      iex> list_translate_languages()
      [%TranslateLanguages{}, ...]

  """
  def list_translate_languages do
    Repo.all(TranslateLanguages)
  end

  @doc """
  Gets a single translate_languages.

  Raises `Ecto.NoResultsError` if the Translate languages does not exist.

  ## Examples

      iex> get_translate_languages!(123)
      %TranslateLanguages{}

      iex> get_translate_languages!(456)
      ** (Ecto.NoResultsError)

  """
  def get_translate_languages!(id), do: Repo.get!(TranslateLanguages, id)

  @doc """
  Creates a translate_languages.

  ## Examples

      iex> create_translate_languages(%{field: value})
      {:ok, %TranslateLanguages{}}

      iex> create_translate_languages(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_translate_languages(attrs \\ %{}) do
    %TranslateLanguages{}
    |> TranslateLanguages.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a translate_languages.

  ## Examples

      iex> update_translate_languages(translate_languages, %{field: new_value})
      {:ok, %TranslateLanguages{}}

      iex> update_translate_languages(translate_languages, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_translate_languages(%TranslateLanguages{} = translate_languages, attrs) do
    translate_languages
    |> TranslateLanguages.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a translate_languages.

  ## Examples

      iex> delete_translate_languages(translate_languages)
      {:ok, %TranslateLanguages{}}

      iex> delete_translate_languages(translate_languages)
      {:error, %Ecto.Changeset{}}

  """
  def delete_translate_languages(%TranslateLanguages{} = translate_languages) do
    Repo.delete(translate_languages)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking translate_languages changes.

  ## Examples

      iex> change_translate_languages(translate_languages)
      %Ecto.Changeset{data: %TranslateLanguages{}}

  """
  def change_translate_languages(%TranslateLanguages{} = translate_languages, attrs \\ %{}) do
    TranslateLanguages.changeset(translate_languages, attrs)
  end

  @spec valid_language_codes :: list
  @doc """
  Returns an `List` of all the valid languages codes

  ## Examples

      iex> valid_language_codes()
      ["ja", "el", "hu", "fil", "zh-Hans", "cy", "da", "sv", "pt-br", "otq", "kn",
  "et", "sr-Cyrl", "ta", "nl", "ml", "vi", "nb", "lv", "id", "gu", "lt", "pt-pt",
  "sr-Latn", "mi", "cs", "ms", "kk", "tlh-Piqd", "te", "fa", "bg", "es", "en",
  "af", "mt", "ca", "ro", "hr", "pa", "ht", "yua", "he", "fj", "ga", "hi", "ko",
  "ur", "zh-Hant", "sk", ...]
  """
  def valid_language_codes do
    valid_languages()
    |> Map.keys()
  end

  def valid_languages do
    %{
      "af" => "Afrikaans",
      "ar" => "Arabic",
      "bn" => "Bangla",
      "bs" => "Bosnian (Latin)",
      "bg" => "Bulgarian",
      "ca" => "Catalan",
      "zh-Hans" => "Chinese Simplified",
      "zh-Hant" => "Chinese Traditional",
      "hr" => "Croatian",
      "cs" => "Czech",
      "da" => "Danish",
      "nl" => "Dutch",
      "en" => "English",
      "et" => "Estonian",
      "fj" => "Fijian",
      "fil" => "Filipino",
      "fi" => "Finnish",
      "fr" => "French",
      "de" => "German",
      "el" => "Greek",
      "gu" => "Gujarati",
      "ht" => "Haitian Creole",
      "he" => "Hebrew",
      "hi" => "Hindi",
      "mww" => "Hmong Daw",
      "hu" => "Hungarian",
      "is" => "Icelandic",
      "id" => "Indonesian",
      "ga" => "Irish",
      "it" => "Italian",
      "ja" => "Japanese",
      "kn" => "Kannada",
      "kk" => "Kazakh",
      "sw" => "Kiswahili",
      "tlh-Latn" => "Klingon",
      "tlh-Piqd" => "Klingon (plqaD)",
      "ko" => "Korean",
      "lv" => "Latvian",
      "lt" => "Lithuanian",
      "mg" => "Malagasy",
      "ms" => "Malay",
      "ml" => "Malayalam",
      "mt" => "Maltese",
      "mi" => "Maori",
      "mr" => "Marathi",
      "nb" => "Norwegian",
      "fa" => "Persian",
      "pl" => "Polish",
      "pt-br" => "Portuguese (Brazil)",
      "pt-pt" => "Portuguese (Portugal)",
      "pa" => "Punjabi",
      "otq" => "Queretaro Otomi",
      "ro" => "Romanian",
      "ru" => "Russian",
      "sm" => "Samoan",
      "sr-Cyrl" => "Serbian (Cyrillic)",
      "sr-Latn" => "Serbian (Latin)",
      "sk" => "Slovak",
      "sl" => "Slovenian",
      "es" => "Spanish",
      "sv" => "Swedish",
      "ty" => "Tahitian",
      "ta" => "Tamil",
      "te" => "Telugu",
      "th" => "Thai",
      "to" => "Tongan",
      "tr" => "Turkish",
      "uk" => "Ukrainian",
      "ur" => "Urdu",
      "vi" => "Vietnamese",
      "cy" => "Welsh",
      "yua" => "Yucatec Maya"
    }
  end
end

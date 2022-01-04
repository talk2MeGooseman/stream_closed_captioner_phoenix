defmodule StreamClosedCaptionerPhoenix.Settings do
  @moduledoc """
  The Settings context.
  """
  @default_languages ["de", "es", "fr", "en"]

  @translatable_languages %{
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
  def translatable_languages, do: @translatable_languages

  @spoken_languages %{
    "Afrikaans" => [
      {"South Africa", "af-ZA"}
    ],
    "Arabic" => [
      {"Algeria", "ar-DZ"},
      {"Bahrain", "ar-BH"},
      {"Egypt", "ar-EG"},
      {"Israel", "ar-IL"},
      {"Iraq", "ar-IQ"},
      {"Jordan", "ar-JO"},
      {"Kuwait", "ar-KW"},
      {"Lebanon", "ar-LB"},
      {"Morocco", "ar-MA"},
      {"Oman", "ar-OM"},
      {"Palestinian Territory", "ar-PS"},
      {"Qatar", "ar-QA"},
      {"Saudi Arabia", "ar-SA"},
      {"Tunisia", "ar-TN"},
      {"UAE", "ar-AE"}
    ],
    "Basque" => [
      {"Spain", "eu-ES"}
    ],
    "Bulgarian" => [
      {"Bulgaria", "bg-BG"}
    ],
    "Catalan" => [
      {"Spain", "ca-ES"}
    ],
    "Chinese Mandarin" => [
      {"China (Simp.)", "cmn-Hans-CN"},
      {"Hong Kong SAR (Trad.)", "cmn-Hans-HK"},
      {"Taiwan (Trad.)", "cmn-Hant-TW"}
    ],
    "Chinese Cantonese" => [
      {"Hong Kong", "yue-Hant-HK"}
    ],
    "Croatian" => [
      {"Croatia", "hr_HR"}
    ],
    "Czech" => [
      {"Czech Republic", "cs-CZ"}
    ],
    "Danish" => [
      {"Denmark", "da-DK"}
    ],
    "English" => [
      {"Australia", "en-AU"},
      {"Canada", "en-CA"},
      {"India", "en-IN"},
      {"Ireland", "en-IE"},
      {"New Zealand", "en-NZ"},
      {"Philippines", "en-PH"},
      {"South Africa", "en-ZA"},
      {"United Kingdom", "en-GB"},
      {"United States", "en-US"}
    ],
    "Farsi" => [
      {"Iran", "fa-IR"}
    ],
    "French" => [
      {"France", "fr-FR"}
    ],
    "Filipino" => [
      {"Philippines", "fil-PH"}
    ],
    "Galician" => [
      {"Spain", "gl-ES"}
    ],
    "German" => [
      {"Germany", "de-DE"}
    ],
    "Greek" => [
      {"Greece", "el-GR"}
    ],
    "Finnish" => [
      {"Finland", "fi-FI"}
    ],
    "Hebrew" => [
      {"Israel", "he-IL"}
    ],
    "Hindi" => [
      {"India", "hi-IN"}
    ],
    "Hungarian" => [
      {"Hungary", "hu-HU"}
    ],
    "Indonesian" => [
      {"Indonesia", "id-ID"}
    ],
    "Icelandic" => [
      {"Iceland", "is-IS"}
    ],
    "Italian" => [
      {"Italy", "it-IT"},
      {"Switzerland", "it-CH"}
    ],
    "Japanese" => [
      {"Japan", "ja-JP"}
    ],
    "Korean" => [
      {"Korea", "ko-KR"}
    ],
    "Lithuanian" => [
      {"Lithuania", "lt-LT"}
    ],
    "Malaysian" => [
      {"Malaysia", "ms-MY"}
    ],
    "Dutch" => [
      {"Netherlands", "nl-NL"}
    ],
    "Norwegian" => [
      {"Norway", "nb-NO"}
    ],
    "Polish" => [
      {"Poland", "pl-PL"}
    ],
    "Portuguese" => [
      {"Brazil", "pt-BR"},
      {"Portugal", "pt-PT"}
    ],
    "Romanian" => [
      {"Romania", "ro-RO"}
    ],
    "Russian" => [
      {"Russia", "ru-RU"}
    ],
    "Serbian" => [
      {"Serbia", "sr-RS"}
    ],
    "Slovak" => [
      {"Slovakia", "sk-SK"}
    ],
    "Slovenian" => [
      {"Slovenia", "sl-SI"}
    ],
    "Spanish" => [
      {"Argentina", "es-AR"},
      {"Bolivia", "es-BO"},
      {"Chile", "es-CL"},
      {"Colombia", "es-CO"},
      {"Costa Rica", "es-CR"},
      {"Dominican Republic", "es-DO"},
      {"Ecuador", "es-EC"},
      {"El Salvador", "es-SV"},
      {"Guatemala", "es-GT"},
      {"Honduras", "es-HN"},
      {"México", "es-MX"},
      {"Nicaragua", "es-NI"},
      {"Panamá", "es-PA"},
      {"Paraguay", "es-PY"},
      {"Perú", "es-PE"},
      {"Puerto Rico", "es-PR"},
      {"Spain", "es-ES"},
      {"Uruguay", "es-UY"},
      {"United States", "es-US"},
      {"Venezuela", "es-VE"}
    ],
    "Swedish" => [
      {"Sweden", "sv-SE"}
    ],
    "Thai" => [
      {"Thailand", "th-TH"}
    ],
    "Turkish" => [
      {"Turkey", "tr-TR"}
    ],
    "Ukrainian" => [
      {"Ukraine", "uk-UA"}
    ],
    "Vietnamese" => [
      {"Viet Nam", "vi-VN"}
    ],
    "Zulu" => [
      {"South Africa", "zu-ZA"}
    ]
  }
  def spoken_languages do
    @spoken_languages
  end

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo

  alias StreamClosedCaptionerPhoenix.Accounts

  alias StreamClosedCaptionerPhoenix.Accounts.{
    User,
    EventsubSubscriptionQueries
  }

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

      iex> create_stream_settings(user, %{field: value})
      {:ok, %StreamSettings{}}

      iex> create_stream_settings(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stream_settings(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:stream_settings)
    |> StreamSettings.create_changeset(attrs)
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
    |> maybe_sync_with_twitch()
    |> manage_eventsub_subscriptions()
  end

  defp manage_eventsub_subscriptions({:error, changeset}), do: {:error, changeset}

  defp manage_eventsub_subscriptions({:ok, stream_settings}) do
    %{user: user} = Repo.preload(stream_settings, :user)

    case stream_settings.turn_on_reminder do
      true ->
        with %{"data" => [%{"id" => id}]} <- Twitch.event_subscribe("stream.online", user.uid) do
          Accounts.create_eventsub_subscription(user, %{
            type: "stream.online",
            subscription_id: id
          })
        end

      false ->
        record = Accounts.fetch_user_eventsub_subscriptions(user, "stream.online")

        if(204 == Twitch.delete_event_subscription(record.subscription_id)) do
          Accounts.delete_eventsub_subscription(record)
        end
    end

    {:ok, stream_settings}
  end

  defp maybe_sync_with_twitch({:error, changeset}), do: {:error, changeset}

  defp maybe_sync_with_twitch({:ok, stream_settings}) do
    # Check if they have an associated Twitch account
    %{user: user} = Repo.preload(stream_settings, :user)

    if(user.provider == "twitch" && is_binary(user.uid)) do
      # Filter fields
      # Format to camelcase
      settings = %{
        language: stream_settings.language,
        textUppercase: stream_settings.text_uppercase || false,
        hideCC: stream_settings.hide_text_on_load || false,
        ccBoxSize: stream_settings.cc_box_size || false,
        switchSettingsPosition: stream_settings.switch_settings_position || false
      }

      # Send to Twitch
      case Twitch.set_extension_broadcaster_configuration_for(user.uid, settings) do
        {:ok, _} -> IO.puts("Sent to Twitch Successfully")
        {:error, _} -> IO.puts("Issue Syncing to Twitch")
      end
    end

    {:ok, stream_settings}
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

  alias StreamClosedCaptionerPhoenix.Settings.TranslateLanguage

  @doc """
  Returns the list of translate_languages.

  ## Examples

      iex> list_translate_languages()
      [%TranslateLanguage{}, ...]

  """
  def list_translate_languages do
    Repo.all(TranslateLanguage)
  end

  @doc """
  Gets a single translate_language.

  Raises `Ecto.NoResultsError` if the Translate languages does not exist.

  ## Examples

      iex> get_translate_language!(123)
      %TranslateLanguage{}

      iex> get_translate_language!(456)
      ** (Ecto.NoResultsError)

  """
  def get_translate_language!(id), do: Repo.get!(TranslateLanguage, id)

  @doc """
  Gets a list of TranslateLanuages by user_id

  Raises `Ecto.NoResultsError` if the Translate languages does not exist.

  ## Examples

      iex> get_translate_languages_by_user!(123)
      [%TranslateLanguage{}]

      iex> get_translate_languages_by_user!(456)
      ** (Ecto.NoResultsError)
  """
  def get_translate_languages_by_user!(user_id),
    do: Repo.get_by!(TranslateLanguage, user_id: user_id)

  @doc """
  Gets a list of TranslateLanuages by user_id

  ## Examples

      iex> get_translate_languages_by_user(456)
      [%TranslateLanguage{}]
  """
  def get_translate_languages_by_user(user_id),
    do: TranslateLanguage |> where(user_id: ^user_id) |> Repo.all()

  @doc """
  Gets a map of the languages that a user would like to translate to

  ## Examples

      iex> get_formatted_translate_languages_by_user(user_id)
      %{en: "English", es: "Spanish", fr: "French"}
  """
  def get_formatted_translate_languages_by_user(user_id) do
    get_translate_languages_by_user(user_id)
    |> Enum.map(fn tl -> tl.language end)
    |> filter_languages
  end

  defp filter_languages([]), do: Map.take(@translatable_languages, @default_languages)
  defp filter_languages(codes), do: Map.take(@translatable_languages, codes)

  @doc """
  Creates a translate_language.

  ## Examples

      iex> create_translate_language(user, %{field: value})
      {:ok, %TranslateLanguage{}}

      iex> create_translate_language(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_translate_language(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:translate_languages)
    |> TranslateLanguage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a translate_language.

  ## Examples

      iex> update_translate_language(translate_language, %{field: new_value})
      {:ok, %TranslateLanguage{}}

      iex> update_translate_language(translate_language, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_translate_language(%TranslateLanguage{} = translate_language, attrs) do
    translate_language
    |> TranslateLanguage.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a translate_language.

  ## Examples

      iex> delete_translate_language(translate_language)
      {:ok, %TranslateLanguage{}}

      iex> delete_translate_language(translate_language)
      {:error, %Ecto.Changeset{}}

  """
  def delete_translate_language(%TranslateLanguage{} = translate_language) do
    Repo.delete(translate_language)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking translate_language changes.

  ## Examples

      iex> change_translate_language(translate_language)
      %Ecto.Changeset{data: %TranslateLanguage{}}

  """
  def change_translate_language(%TranslateLanguage{} = translate_language, attrs \\ %{}) do
    TranslateLanguage.changeset(translate_language, attrs)
  end

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
    @translatable_languages
    |> Map.keys()
  end

  @doc """
  Returns an `List` of tuple pairs containing the name of the language and
  the language code.

  ## Examples

      iex> translateable_language_list()
      [{"English, "en"}, {"Spanish", "es"}, ...]
  """
  @spec translateable_language_list :: [{String, String}]
  def translateable_language_list,
    do:
      @translatable_languages
      |> Enum.sort()
      |> Enum.map(fn {v1, v2} -> {v2, v1} end)
end

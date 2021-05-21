defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  alias Azure.Cognitive.Translations
  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.{Profanity, Translations}
  alias Twitch.Extension.CaptionsPayload

  @type message_map :: %{
          required(:final) => String.t(),
          required(:interim) => String.t(),
          required(:session) => String.t()
        }

  @spec pipeline_to(
          :twitch | :zoom | :default,
          StreamClosedCaptionerPhoenix.Accounts.User.t(),
          message_map()
        ) ::
          {:error, String.t()}
          | {:ok, CaptionsPayload.t()}

  def pipeline_to(:zoom, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    params = %Zoom.Params{
      seq: get_in(message, ["zoom", "seq"]),
      lang: user.stream_settings.language
    }

    payload =
      CaptionsPayload.new(message)
      |> maybe_censor_for(:interim, user)
      |> maybe_censor_for(:final, user)

    url = get_in(message, ["zoom", "url"])
    text = Map.get(payload, :final)

    case Zoom.send_captions_to(url, text, params) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        IO.puts("Request was rejected code: #{code} body: #{body}")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Request was error")
        {:error, reason}
    end
  end

  def pipeline_to(:twitch, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    CaptionsPayload.new(message)
    |> maybe_censor_for(:interim, user)
    |> maybe_censor_for(:final, user)
    |> Translations.maybe_translate(:final, user)
    |> send_to(:twitch, user)
  end

  def pipeline_to(:default, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    payload =
      CaptionsPayload.new(message)
      |> maybe_censor_for(:interim, user)
      |> maybe_censor_for(:final, user)

    {:ok, payload}
  end

  defp send_to(payload, :twitch, user) do
    case Twitch.send_pubsub_message(payload, user.uid) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        IO.puts("Request was rejected")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Request was error")
        {:error, reason}
    end
  end

  defp maybe_censor_for(payload, key, %User{} = user) do
    Map.put(
      payload,
      key,
      Profanity.maybe_censor(user.stream_settings, Map.get(payload, key))
    )
  end
end

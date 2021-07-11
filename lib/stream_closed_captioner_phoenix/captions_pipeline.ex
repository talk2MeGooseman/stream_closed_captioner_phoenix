defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline do
  require Logger

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
  def pipeline_to(:default, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    payload =
      CaptionsPayload.new(message)
      |> maybe_censor_for(:interim, user)
      |> maybe_censor_for(:final, user)

    {:ok, payload}
  end

  def pipeline_to(:twitch, %User{} = user, message) do
    user = Repo.preload(user, :stream_settings)

    CaptionsPayload.new(message)
    |> maybe_censor_for(:interim, user)
    |> maybe_censor_for(:final, user)
    |> Translations.maybe_translate(:final, user)
    |> rate_limited_twitch_send(user)
  end

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

    zoom_text = Map.get(payload, :final)
    url = get_in(message, ["zoom", "url"])

    case Zoom.send_captions_to(url, zoom_text, params) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, payload}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        Logger.debug("Request was rejected code: #{code} body: #{body}")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.debug("Request was error")
        {:error, reason}
    end
  end

  defp rate_limited_twitch_send(payload, user) do
    case Hammer.check_rate("twitch:pubsub:#{user.id}", 800, 1) do
      {:allow, _count} ->
        Twitch.send_pubsub_message(payload, user.uid)

      {:deny, limit} ->
        Logger.debug("Limit Reached: #{limit}")
        {:error, "Rate limit reached for message to Twitch"}
    end
  end

  defp maybe_censor_for(payload, key, %User{} = user) do
    Map.put(
      payload,
      key,
      Profanity.maybe_censor(user.stream_settings, Map.get(payload, key))
    )
  end

  defp maybe_pirate_mode_for(payload, key, %User{} = user) do
    if user.stream_settings.pirate_mode do
      {:ok, text} = TalkLikeAX.translate(Map.get(payload, key))

      Map.put(
        payload,
        key,
        text
      )
    else
      payload
    end
  end
end

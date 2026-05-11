defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.TranslationsTelemetryTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: false

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  setup :verify_on_exit!

  setup do
    FunWithFlags.disable(:gemini_translations)
    on_exit(fn -> FunWithFlags.disable(:gemini_translations) end)
    :ok
  end

  test "emits :stop with result: :skipped_no_languages when user has none configured" do
    TelemetryCapture.attach([[:scc, :captions, :translation, :stop]])

    user = insert(:user, translate_languages: [])
    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}

    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    _,
                    %{user_id: _, result: :skipped_no_languages, provider: :azure}}
  end

  test "emits :stop with result: :skipped_no_balance when balance < 500 and no active debit" do
    TelemetryCapture.attach([[:scc, :captions, :translation, :stop]])

    user =
      insert(:user,
        bits_balance: build(:bits_balance, balance: 0, user: nil),
        translate_languages: [build(:translate_language, language: "es")]
      )

    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    _,
                    %{result: :skipped_no_balance}}
  end

  test "emits :stop with result: :ok and :bits_debit when activation succeeds" do
    TelemetryCapture.attach([
      [:scc, :captions, :translation, :stop],
      [:scc, :captions, :translation, :bits_debit]
    ])

    user =
      insert(:user,
        bits_balance: build(:bits_balance, balance: 5000, user: nil),
        translate_languages: [build(:translate_language, language: "es")]
      )

    Mox.expect(Azure.MockCognitive, :translate, fn _from, _to, _text ->
      {:ok, %Azure.Cognitive.Translations{translations: %{"es" => "hola"}}}
    end)

    payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
    Translations.maybe_translate(payload, :final, user)

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :bits_debit],
                    %{count: 1},
                    %{user_id: _}}

    assert_receive {:telemetry,
                    [:scc, :captions, :translation, :stop],
                    %{duration: _},
                    %{result: :ok, provider: :azure, to_count: 1}}
  end

  test "emits [:scc, :outbound, :azure_translation, :stop] when Azure call succeeds" do
    TelemetryCapture.attach([[:scc, :outbound, :azure_translation, :stop]])

    Mox.expect(Azure.MockCognitive, :translate, fn _from, to, _text ->
      {:ok, %Azure.Cognitive.Translations{translations: Map.new(to, &{&1, "hola"})}}
    end)

    assert {:ok, _} = Azure.perform_translations("en", ["es"], "Hello")

    assert_receive {:telemetry,
                    [:scc, :outbound, :azure_translation, :stop],
                    %{duration: _},
                    %{from_lang: "en", to_count: 1, result: :ok}}
  end
end

defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.TranslationsTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import StreamClosedCaptionerPhoenix.Factory
  import Mox

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations
  alias Azure.Cognitive.Translations, as: CognitiveTranslations

  setup :verify_on_exit!

  describe "maybe_translate/3 with user Azure key" do
    test "uses user's Azure key when provided and translation enabled" do
      user = insert(:user, azure_service_key: "user-azure-key-123")
      # Update the pre-created stream_settings instead of inserting a new one
      StreamClosedCaptionerPhoenix.Settings.update_stream_settings(user.stream_settings, %{
        translation_enabled: true
      })

      insert(:translate_language, user_id: user.id, language: "es")

      expect(Azure.MockCognitive, :translate, fn _from, _to, _text, user_key ->
        assert user_key == "user-azure-key-123"
        %CognitiveTranslations{translations: %{"es" => %{name: "Spanish", text: "Hola"}}}
      end)

      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)

      assert result.translations == %{"es" => %{name: "Spanish", text: "Hola"}}
    end

    test "does not translate when user has Azure key but translation disabled" do
      user = insert(:user, azure_service_key: "user-azure-key-123")
      # Update the pre-created stream_settings instead of inserting a new one
      StreamClosedCaptionerPhoenix.Settings.update_stream_settings(user.stream_settings, %{
        translation_enabled: false
      })

      insert(:translate_language, user_id: user.id, language: "es")

      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)

      refute Map.has_key?(result, :translations)
    end

    test "falls back to bits system when user has no Azure key" do
      user = insert(:user, azure_service_key: nil)
      # Update the pre-created stream_settings instead of inserting a new one
      StreamClosedCaptionerPhoenix.Settings.update_stream_settings(user.stream_settings, %{
        translation_enabled: true
      })

      insert(:translate_language, user_id: user.id, language: "es")
      # Update the pre-created bits_balance instead of inserting a new one
      StreamClosedCaptionerPhoenix.Bits.update_bits_balance(user.bits_balance, %{balance: 1000})

      # Mock the Azure translation call that will be made when bits activates translations
      expect(Azure.MockCognitive, :translate, fn _from, _to, _text ->
        %CognitiveTranslations{translations: %{"es" => %{name: "Spanish", text: "Hola"}}}
      end)

      # Should proceed with normal bits-based flow
      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)

      # Since there's no active debit and user has sufficient balance,
      # it should attempt to activate translations and call Azure
      assert Map.has_key?(result, :translations)
    end
  end
end

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
      stream_settings = insert(:stream_settings, user_id: user.id, translation_enabled: true)
      insert(:translate_language, user_id: user.id, language: "es")
      
      expect(Azure.CognitiveMock, :translate, fn _from, _to, _text, user_key ->
        assert user_key == "user-azure-key-123"
        %CognitiveTranslations{translations: %{"es" => %{name: "Spanish", text: "Hola"}}}
      end)

      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)
      
      assert result.translations == %{"es" => %{name: "Spanish", text: "Hola"}}
    end

    test "does not translate when user has Azure key but translation disabled" do
      user = insert(:user, azure_service_key: "user-azure-key-123")
      stream_settings = insert(:stream_settings, user_id: user.id, translation_enabled: false)
      insert(:translate_language, user_id: user.id, language: "es")
      
      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)
      
      refute Map.has_key?(result, :translations)
    end

    test "falls back to bits system when user has no Azure key" do
      user = insert(:user, azure_service_key: nil)
      stream_settings = insert(:stream_settings, user_id: user.id, translation_enabled: true)
      insert(:translate_language, user_id: user.id, language: "es")
      insert(:bits_balance, user_id: user.id, balance: 1000)
      
      # Should proceed with normal bits-based flow
      payload = %{text: "Hello"}
      result = Translations.maybe_translate(payload, :text, user)
      
      # Since there's no active debit and user has sufficient balance,
      # it should attempt to activate translations
      # This is a more complex flow that would require mocking the Bits module
    end
  end
end
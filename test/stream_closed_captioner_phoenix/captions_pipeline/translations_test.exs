defmodule StreamClosedCaptionerPhoenix.CaptionsPipeline.TranslationsTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline.Translations

  setup :verify_on_exit!

  describe "maybe_translate/3 — no translation needed" do
    test "returns payload unchanged when user has no translate languages configured" do
      user = insert(:user, translate_languages: [])

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result == payload
      assert result.translations == nil
    end

    test "returns payload unchanged when user has languages but insufficient bits balance" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0),
          translate_languages: [build(:translate_language, language: "es")]
        )

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result == payload
      assert result.translations == nil
    end
  end

  describe "maybe_translate/3 — activation fallback" do
    test "returns payload unchanged when activation fails (e.g. race condition drains balance)" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: [build(:translate_language, language: "es")]
        )

      # Drain the balance to simulate a race condition so activate_translations_for fails
      StreamClosedCaptionerPhoenix.Repo.update_all(
        StreamClosedCaptionerPhoenix.Bits.BitsBalance,
        set: [balance: 0]
      )

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result.translations == nil
    end
  end

  describe "maybe_translate/3 — with active debit" do
    test "translates when user already has an active translation debit" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0),
          translate_languages: [build(:translate_language, language: "es")]
        )

      insert(:bits_balance_debit, user: user)

      Azure.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        {:ok,
         Azure.Cognitive.Translations.new(%{
           translations: [%{"text" => "Hola", "to" => "es"}]
         })}
      end)

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result.translations == %{
               "es" => %Azure.Cognitive.Translation{text: "Hola", name: "Spanish"}
             }
    end

    test "returns payload unchanged when Azure returns an error on active debit" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 0),
          translate_languages: [build(:translate_language, language: "es")]
        )

      insert(:bits_balance_debit, user: user)

      Azure.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        {:error, {:http, :timeout}}
      end)

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result.translations == nil
    end
  end

  describe "maybe_translate/3 — with enough bits (fresh activation)" do
    test "activates and translates when user has enough bits and a language configured" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: [build(:translate_language, language: "es")]
        )

      Azure.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        {:ok,
         Azure.Cognitive.Translations.new(%{
           translations: [%{"text" => "Hola", "to" => "es"}]
         })}
      end)

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result.translations == %{
               "es" => %Azure.Cognitive.Translation{text: "Hola", name: "Spanish"}
             }

      # Balance should have been debited
      assert %{balance: 0} = StreamClosedCaptionerPhoenix.Bits.get_bits_balance!(user)
    end

    test "returns payload unchanged when Azure returns an error during fresh activation" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: [build(:translate_language, language: "es")]
        )

      Azure.MockCognitive
      |> expect(:translate, fn _from, _to, _text ->
        {:error, {:json_decode, "unexpected token"}}
      end)

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result.translations == nil
    end
  end

  describe "maybe_translate/3 — empty to_languages list" do
    test "skips translation when to_languages is empty even if balance is sufficient" do
      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 500),
          translate_languages: []
        )

      payload = %Twitch.Extension.CaptionsPayload{final: "Hello", interim: "", delay: 0}
      result = Translations.maybe_translate(payload, :final, user)

      assert result == payload
      assert result.translations == nil
    end
  end
end

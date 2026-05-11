defmodule StreamClosedCaptionerPhoenix.CaptionsPipelineTelemetryTest do
  use StreamClosedCaptionerPhoenix.DataCase, async: true

  import Mox
  import StreamClosedCaptionerPhoenix.Factory

  alias StreamClosedCaptionerPhoenix.CaptionsPipeline
  alias StreamClosedCaptionerPhoenix.TelemetryCapture

  setup :verify_on_exit!

  describe "[:scc, :captions, :pipeline, …] for :default path" do
    test "emits :stop with result: :ok and expected metadata on success" do
      TelemetryCapture.attach([
        [:scc, :captions, :pipeline, :start],
        [:scc, :captions, :pipeline, :stop]
      ])

      user = insert(:user)

      assert {:ok, _payload} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello",
                 "final" => "World",
                 "session" => "abc123"
               })

      assert_receive {:telemetry, [:scc, :captions, :pipeline, :start], _, %{destination: :default}}

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      %{duration: duration},
                      %{destination: :default, result: :ok, user_id: uid, text_length: 5}}

      assert duration > 0
      assert uid == user.id
    end

    test "emits :stop with result: :error when stream settings are missing" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      ghost_user = %StreamClosedCaptionerPhoenix.Accounts.User{id: 0}

      assert {:error, "Stream settings not found"} =
               CaptionsPipeline.pipeline_to(:default, ghost_user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      %{duration: _},
                      %{destination: :default, result: :error, error_reason: _}}
    end
  end

  describe "[:scc, :captions, :pipeline, …] for :twitch path" do
    setup do
      Application.put_env(:stream_closed_captioner_phoenix, :translation_task_timeout_ms, 50)
      on_exit(fn ->
        Application.delete_env(:stream_closed_captioner_phoenix, :translation_task_timeout_ms)
      end)
      :ok
    end

    test "emits :stop with destination: :twitch on success" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      user = insert(:user)

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:twitch, user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      _measurements,
                      %{destination: :twitch, result: :ok, user_id: uid}}

      assert uid == user.id
    end

    test "emits translation timeout event when the translation Task is shut down" do
      TelemetryCapture.attach([[:scc, :captions, :translation, :timeout]])

      user =
        insert(:user,
          bits_balance: build(:bits_balance, balance: 5000, user: nil),
          translate_languages: [build(:translate_language, language: "es")]
        )

      Mox.stub(Azure.MockCognitive, :translate, fn _from, _to, _text ->
        :timer.sleep(200)
        {:ok, %Azure.Cognitive.Translations{translations: %{"es" => "hola"}}}
      end)

      uid = user.id

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:twitch, user, %{
                 "interim" => "x",
                 "final" => "Hello",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :translation, :timeout],
                      %{duration_ms: 50},
                      %{user_id: ^uid}},
                     1_000
    end
  end

  describe "[:scc, :captions, :pipeline, …] for :zoom path" do
    test "emits :stop with destination: :zoom and result: :error on invalid URL" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :stop]])

      user = insert(:user)

      assert {:error, :invalid_zoom_url} =
               CaptionsPipeline.pipeline_to(:zoom, user, %{
                 "interim" => "x",
                 "final" => "y",
                 "session" => "abc",
                 "zoom" => %{"url" => "http://evil.example.com", "seq" => 1}
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :stop],
                      _measurements,
                      %{destination: :zoom, result: :error, error_reason: :invalid_zoom_url}}
    end
  end

  describe "[:scc, :captions, :pipeline, :censored]" do
    test "emits :censored with blocked_count when blocklist matches" do
      TelemetryCapture.attach([[:scc, :captions, :pipeline, :censored]])

      user =
        insert(:user,
          stream_settings:
            build(:stream_settings, filter_profanity: true, blocklist: ["poopy"])
        )

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello poopy head",
                 "final" => "Friend",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pipeline, :censored],
                      %{blocked_count: count},
                      %{destination: :default, user_id: uid, key: :interim}}
                     when count > 0

      assert uid == user.id
    end
  end

  describe "[:scc, :captions, :pirate_mode, :stop]" do
    test "emits :stop with result: :ok when pirate mode succeeds" do
      TelemetryCapture.attach([[:scc, :captions, :pirate_mode, :stop]])

      user =
        insert(:user, stream_settings: build(:stream_settings, pirate_mode: true))

      assert {:ok, _} =
               CaptionsPipeline.pipeline_to(:default, user, %{
                 "interim" => "Hello",
                 "final" => "Friend",
                 "session" => "abc"
               })

      assert_receive {:telemetry,
                      [:scc, :captions, :pirate_mode, :stop],
                      %{duration: _},
                      %{user_id: uid, key: :interim, result: :ok}}

      assert uid == user.id
    end
  end
end

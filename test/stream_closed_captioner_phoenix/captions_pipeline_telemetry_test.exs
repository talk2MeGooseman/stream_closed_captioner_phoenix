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
end

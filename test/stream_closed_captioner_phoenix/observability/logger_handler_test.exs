defmodule StreamClosedCaptionerPhoenix.Observability.LoggerHandlerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias StreamClosedCaptionerPhoenix.Observability.LoggerHandler

  setup do
    :ok = LoggerHandler.attach()
    on_exit(fn -> :telemetry.detach("scc-observability-error-logs") end)
    :ok
  end

  test "pipeline :stop with result: :error produces a structured Logger.error line" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            user_id: 42,
            result: :error,
            error_reason: :boom,
            text_length: 10,
            language: "en-US"
          }
        )
      end)

    assert log =~ "[error]"
    assert log =~ "caption pipeline returned error"
  end

  test "pipeline :stop with result: :ok produces no log" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{destination: :default, result: :ok, user_id: 1, text_length: 5, language: nil}
        )
      end)

    refute log =~ "caption pipeline"
  end

  test "pipeline :exception event produces error log with formatted stacktrace" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :exception],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            kind: :error,
            reason: %RuntimeError{message: "boom"},
            stacktrace: [{Mod, :fun, 0, [file: ~c"x.ex", line: 1]}],
            user_id: 99
          }
        )
      end)

    assert log =~ "[error]"
    assert log =~ "caption pipeline raised"
  end

  test "log line never contains access_token value (PII guard)" do
    secret = "TOPSECRET-#{System.unique_integer()}"
    user = %StreamClosedCaptionerPhoenix.Accounts.User{id: 99, access_token: secret}

    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :pipeline, :stop],
          %{duration: 1_000_000},
          %{
            destination: :twitch,
            user_id: user.id,
            user_struct: user,
            result: :error,
            error_reason: :boom,
            text_length: 5,
            language: "en"
          }
        )
      end)

    refute log =~ secret
  end

  test "translation :timeout produces a warning log" do
    log =
      capture_log(fn ->
        :telemetry.execute(
          [:scc, :captions, :translation, :timeout],
          %{duration_ms: 50},
          %{user_id: 1}
        )
      end)

    assert log =~ "[warning]"
    assert log =~ "translation timed out"
  end
end

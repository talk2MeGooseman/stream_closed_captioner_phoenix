defmodule StreamClosedCaptionerPhoenix.TranscriptsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StreamClosedCaptionerPhoenix.Transcripts` context.
  """

  import StreamClosedCaptionerPhoenix.AccountsFixtures

  def transcript_fixture(attrs \\ %{}) do
    {:ok, transcript} =
      attrs
      |> Enum.into(%{
        name: "some name",
        session: "some session",
        user_id: user_fixture().id
      })
      |> StreamClosedCaptionerPhoenix.Transcripts.create_transcript()

    transcript
  end

  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        text: "some text",
        transcript_id: transcript_fixture().id
      })
      |> StreamClosedCaptionerPhoenix.Transcripts.create_message()

    message
  end
end

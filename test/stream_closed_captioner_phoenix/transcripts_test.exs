defmodule StreamClosedCaptionerPhoenix.TranscriptsTest do
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.Transcripts
  import StreamClosedCaptionerPhoenix.AccountsFixtures
  import StreamClosedCaptionerPhoenix.TranscriptsFixtures

  describe "transcripts" do
    alias StreamClosedCaptionerPhoenix.Transcripts.Transcript

    @update_attrs %{name: "some updated name", session: "some updated session", user_id: 43}
    @invalid_attrs %{name: nil, session: nil, user_id: nil}

    test "list_transcripts/0 returns all transcripts" do
      transcript = transcript_fixture()
      assert Transcripts.list_transcripts() == [transcript]
    end

    test "get_transcript!/1 returns the transcript with given id" do
      transcript = transcript_fixture()
      assert Transcripts.get_transcript!(transcript.id) == transcript
    end

    test "get_users_transcript!/2 returns the transcript with given id" do
      transcript = transcript_fixture()

      assert Transcripts.get_users_transcript!(%{id: transcript.user_id}, transcript.id) ==
               transcript
    end

    test "create_transcript/1 with valid data creates a transcript" do
      user = user_fixture()

      attrs = %{
        name: "some name",
        session: "some session",
        user_id: user.id
      }

      assert {:ok, %Transcript{} = transcript} = Transcripts.create_transcript(attrs)
      assert transcript.name == "some name"
      assert transcript.session == "some session"
      assert transcript.user_id == user.id
    end

    test "create_transcript/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transcripts.create_transcript(@invalid_attrs)
    end

    test "update_transcript/2 with valid data updates the transcript" do
      transcript = transcript_fixture()

      assert {:ok, %Transcript{} = transcript} =
               Transcripts.update_transcript(transcript, @update_attrs)

      assert transcript.name == "some updated name"
      assert transcript.session == transcript.session
      assert transcript.user_id == transcript.user_id
    end

    test "update_transcript/2 with invalid data returns error changeset" do
      transcript = transcript_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Transcripts.update_transcript(transcript, @invalid_attrs)

      assert transcript == Transcripts.get_transcript!(transcript.id)
    end

    test "delete_transcript/1 deletes the transcript" do
      transcript = transcript_fixture()
      assert {:ok, %Transcript{}} = Transcripts.delete_transcript(transcript)
      assert_raise Ecto.NoResultsError, fn -> Transcripts.get_transcript!(transcript.id) end
    end

    test "change_transcript/1 returns a transcript changeset" do
      transcript = transcript_fixture()
      assert %Ecto.Changeset{} = Transcripts.change_transcript(transcript)
    end
  end

  describe "messages" do
    alias StreamClosedCaptionerPhoenix.Transcripts.Message

    @update_attrs %{text: "some updated text", transcript_id: 42}
    @invalid_attrs %{text: nil, transcript_id: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Transcripts.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Transcripts.get_message!(message.id) == message
    end

    test "get_transcripts_message!/2 returns the message with given id" do
      message = message_fixture()

      assert Transcripts.get_transcripts_message!(%{ id: message.transcript_id }, message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      transcript = transcript_fixture()
      valid_params = %{text: "other text", transcript_id: transcript.id}

      assert {:ok, %Message{} = message} = Transcripts.create_message(valid_params)
      assert message.text == "other text"
      assert message.transcript_id == transcript.id
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transcripts.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, %Message{} = message} = Transcripts.update_message(message, @update_attrs)
      assert message.text == "some updated text"
      assert message.transcript_id == message.transcript_id
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Transcripts.update_message(message, @invalid_attrs)
      assert message == Transcripts.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Transcripts.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Transcripts.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Transcripts.change_message(message)
    end
  end
end

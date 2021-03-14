defmodule StreamClosedCaptionerPhoenix.TranscriptsTest do
  import StreamClosedCaptionerPhoenix.Factory
  use StreamClosedCaptionerPhoenix.DataCase

  alias StreamClosedCaptionerPhoenix.{Transcripts, Repo}
  import StreamClosedCaptionerPhoenix.AccountsFixtures
  import StreamClosedCaptionerPhoenix.TranscriptsFixtures

  describe "transcripts" do
    alias StreamClosedCaptionerPhoenix.Transcripts.Transcript

    @update_attrs %{name: "some updated name", session: "some updated session"}
    @invalid_attrs %{name: nil, session: nil}

    test "list_transcripts/0 returns all transcripts" do
      transcripts = insert_list(3, :transcript)
      assert Transcripts.list_transcripts() |> Repo.preload(:user) == transcripts
    end

    test "get_transcript!/1 returns the transcript with given id" do
      transcript = insert(:transcript)
      assert Transcripts.get_transcript!(transcript.id) |> Repo.preload(:user) == transcript
    end

    test "get_users_transcript!/2 returns the transcript with given id" do
      transcript = insert(:transcript)

      assert Transcripts.get_users_transcript!(transcript.user, transcript.id)
             |> Repo.preload(:user) ==
               transcript
    end

    test "create_transcript/1 with valid data creates a transcript" do
      user = insert(:user)
      attrs = params_for(:transcript)

      assert {:ok, %Transcript{} = transcript} = Transcripts.create_transcript(user, attrs)
      assert transcript.name == attrs.name
      assert transcript.session == attrs.session
      assert transcript.user_id == user.id
    end

    test "create_transcript/1 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Transcripts.create_transcript(user, @invalid_attrs)
    end

    test "update_transcript/2 with valid data updates the transcript" do
      transcript = insert(:transcript)

      assert {:ok, %Transcript{} = updated_transcript} =
               Transcripts.update_transcript(transcript, @update_attrs)

      assert updated_transcript.name == "some updated name"
      assert updated_transcript.session == transcript.session
      assert updated_transcript.user_id == transcript.user_id
    end

    test "update_transcript/2 with invalid data returns error changeset" do
      transcript = insert(:transcript)

      assert {:error, %Ecto.Changeset{}} =
               Transcripts.update_transcript(transcript, @invalid_attrs)

      assert transcript == Transcripts.get_transcript!(transcript.id) |> Repo.preload(:user)
    end

    test "delete_transcript/1 deletes the transcript" do
      transcript = insert(:transcript)
      assert {:ok, %Transcript{}} = Transcripts.delete_transcript(transcript)
      assert_raise Ecto.NoResultsError, fn -> Transcripts.get_transcript!(transcript.id) end
    end

    test "change_transcript/1 returns a transcript changeset" do
      transcript = insert(:transcript)
      assert %Ecto.Changeset{} = Transcripts.change_transcript(transcript)
    end
  end

  describe "messages" do
    alias StreamClosedCaptionerPhoenix.Transcripts.Message

    @update_attrs %{text: "some updated text"}
    @invalid_attrs %{text: nil, transcript_id: nil}

    test "get_message!/2 returns the message with given id" do
      message = insert(:message)
      expected = Transcripts.get_message!(message.id)

      assert Map.drop(expected, [:transcript]) ==
               Map.drop(message, [:transcript])
    end

    test "get_transcripts_message!/2 returns the message with given id" do
      message = insert(:message)
      expected = Transcripts.get_transcripts_message!(message.transcript, message.id)

      assert Map.drop(expected, [:transcript]) ==
               Map.drop(message, [:transcript])
    end

    test "create_message/1 with valid data creates a message" do
      transcript = insert(:transcript)
      valid_params = %{text: "other text"}

      assert {:ok, %Message{} = message} = Transcripts.create_message(transcript, valid_params)
      assert message.text == "other text"
      assert message.transcript_id == transcript.id
    end

    test "create_message/1 with invalid data returns error changeset" do
      transcript = insert(:transcript)
      assert {:error, %Ecto.Changeset{}} = Transcripts.create_message(transcript, @invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = insert(:message)

      assert {:ok, %Message{} = updated_message} =
               Transcripts.update_message(message, @update_attrs)

      assert updated_message.text == "some updated text"
      assert updated_message.transcript_id == message.transcript_id
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = insert(:message)
      assert {:error, %Ecto.Changeset{}} = Transcripts.update_message(message, @invalid_attrs)

      assert Map.drop(message, [:transcript]) ==
               Map.drop(Transcripts.get_message!(message.id), [:transcript])
    end

    test "delete_message/1 deletes the message" do
      message = insert(:message)
      assert {:ok, %Message{}} = Transcripts.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Transcripts.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = insert(:message)
      assert %Ecto.Changeset{} = Transcripts.change_message(message)
    end
  end
end

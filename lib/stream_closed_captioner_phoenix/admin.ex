defmodule StreamClosedCaptionerPhoenix.Admin do
  import Ecto.Query
  import Ecto.Changeset

  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Accounts.{User, UserToken, EventsubSubscription}
  alias StreamClosedCaptionerPhoenix.Bits.{BitsBalance, BitsTransaction, BitsBalanceDebit}
  alias StreamClosedCaptionerPhoenix.Settings.{StreamSettings, TranslateLanguage}
  alias StreamClosedCaptionerPhoenix.Transcripts.{Transcript, Message}
  alias StreamClosedCaptionerPhoenix.Announcement

  @page_size 25

  def page_size, do: @page_size

  # --- Users ---

  def list_users(search \\ nil, page \\ 1) do
    User
    |> search_users(search)
    |> order_by([u], desc: u.id)
    |> paginate(page)
    |> Repo.all()
  end

  def count_users(search \\ nil) do
    User |> search_users(search) |> Repo.aggregate(:count)
  end

  def get_user!(id) do
    Repo.get!(User, id)
    |> Repo.preload([
      :bits_balance,
      :stream_settings,
      :translate_languages,
      :transcripts,
      :eventsub_subscriptions,
      :bits_transactions,
      :bits_balance_debits
    ])
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [
      :email,
      :username,
      :login,
      :description,
      :profile_image_url,
      :offline_image_url,
      :uid,
      :provider,
      :sign_in_count,
      :access_token,
      :refresh_token
    ])
  end

  def create_user(attrs) do
    %User{}
    |> cast(attrs, [:email, :username, :login, :description, :uid, :provider])
    |> validate_required([:email, :username])
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :username,
      :login,
      :description,
      :profile_image_url,
      :offline_image_url,
      :uid,
      :provider,
      :sign_in_count,
      :access_token,
      :refresh_token
    ])
    |> Repo.update()
  end

  def delete_user(%User{} = user), do: Repo.delete(user)

  defp search_users(query, nil), do: query
  defp search_users(query, ""), do: query

  defp search_users(query, s),
    do:
      where(
        query,
        [u],
        ilike(u.username, ^"%#{s}%") or ilike(u.email, ^"%#{s}%") or ilike(u.uid, ^"%#{s}%")
      )

  # --- Announcements ---

  def list_announcements(search \\ nil, page \\ 1) do
    Announcement
    |> search_announcements(search)
    |> order_by([a], desc: a.id)
    |> paginate(page)
    |> Repo.all()
  end

  def count_announcements(search \\ nil) do
    Announcement |> search_announcements(search) |> Repo.aggregate(:count)
  end

  def get_announcement!(id), do: Repo.get!(Announcement, id)
  def change_announcement(%Announcement{} = a, attrs \\ %{}), do: Announcement.changeset(a, attrs)

  def create_announcement(attrs),
    do: %Announcement{} |> Announcement.changeset(attrs) |> Repo.insert()

  def update_announcement(%Announcement{} = a, attrs),
    do: a |> Announcement.changeset(attrs) |> Repo.update()

  def delete_announcement(%Announcement{} = a), do: Repo.delete(a)

  defp search_announcements(query, nil), do: query
  defp search_announcements(query, ""), do: query
  defp search_announcements(query, s), do: where(query, [a], ilike(a.message, ^"%#{s}%"))

  # --- BitsBalance ---

  def list_bits_balances(search \\ nil, page \\ 1) do
    BitsBalance
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> order_by([b], desc: b.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_bits_balances(search \\ nil) do
    BitsBalance
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> Repo.aggregate(:count)
  end

  def get_bits_balance!(id), do: Repo.get!(BitsBalance, id) |> Repo.preload(:user)
  def change_bits_balance(%BitsBalance{} = b, attrs \\ %{}), do: BitsBalance.changeset(b, attrs)

  def create_bits_balance(attrs),
    do: %BitsBalance{} |> BitsBalance.changeset(attrs) |> Repo.insert()

  def update_bits_balance(%BitsBalance{} = b, attrs),
    do: b |> BitsBalance.update_changeset(attrs) |> Repo.update()

  def delete_bits_balance(%BitsBalance{} = b), do: Repo.delete(b)

  # --- BitsTransaction ---

  def list_bits_transactions(search \\ nil, page \\ 1) do
    BitsTransaction
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> order_by([b], desc: b.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_bits_transactions(search \\ nil) do
    BitsTransaction
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> Repo.aggregate(:count)
  end

  def get_bits_transaction!(id), do: Repo.get!(BitsTransaction, id) |> Repo.preload(:user)

  def change_bits_transaction(%BitsTransaction{} = b, attrs \\ %{}),
    do: BitsTransaction.changeset(b, attrs)

  def create_bits_transaction(attrs),
    do: %BitsTransaction{} |> BitsTransaction.changeset(attrs) |> Repo.insert()

  def update_bits_transaction(%BitsTransaction{} = b, attrs),
    do: b |> BitsTransaction.changeset(attrs) |> Repo.update()

  def delete_bits_transaction(%BitsTransaction{} = b), do: Repo.delete(b)

  # --- BitsBalanceDebit ---

  def list_bits_balance_debits(search \\ nil, page \\ 1) do
    BitsBalanceDebit
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> order_by([b], desc: b.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_bits_balance_debits(search \\ nil) do
    BitsBalanceDebit
    |> join(:left, [b], u in assoc(b, :user), as: :user)
    |> search_by_user(search)
    |> Repo.aggregate(:count)
  end

  def get_bits_balance_debit!(id), do: Repo.get!(BitsBalanceDebit, id) |> Repo.preload(:user)

  def change_bits_balance_debit(%BitsBalanceDebit{} = b, attrs \\ %{}),
    do: BitsBalanceDebit.changeset(b, attrs)

  def create_bits_balance_debit(attrs),
    do: %BitsBalanceDebit{} |> BitsBalanceDebit.changeset(attrs) |> Repo.insert()

  def update_bits_balance_debit(%BitsBalanceDebit{} = b, attrs),
    do: b |> BitsBalanceDebit.changeset(attrs) |> Repo.update()

  def delete_bits_balance_debit(%BitsBalanceDebit{} = b), do: Repo.delete(b)

  # --- Transcripts ---

  def list_transcripts(search \\ nil, page \\ 1) do
    Transcript
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_transcripts(search)
    |> order_by([t], desc: t.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_transcripts(search \\ nil) do
    Transcript
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_transcripts(search)
    |> Repo.aggregate(:count)
  end

  def get_transcript!(id), do: Repo.get!(Transcript, id) |> Repo.preload([:user, :messages])
  def change_transcript(%Transcript{} = t, attrs \\ %{}), do: Transcript.changeset(t, attrs)
  def create_transcript(attrs), do: %Transcript{} |> Transcript.changeset(attrs) |> Repo.insert()

  def update_transcript(%Transcript{} = t, attrs),
    do: t |> Transcript.update_changeset(attrs) |> Repo.update()

  def delete_transcript(%Transcript{} = t), do: Repo.delete(t)

  defp search_transcripts(query, nil), do: query
  defp search_transcripts(query, ""), do: query

  defp search_transcripts(query, s),
    do: where(query, [t, user: u], ilike(t.name, ^"%#{s}%") or ilike(u.username, ^"%#{s}%"))

  # --- Messages ---

  def list_messages(search \\ nil, page \\ 1) do
    Message
    |> join(:left, [m], t in assoc(m, :transcript), as: :transcript)
    |> search_messages(search)
    |> order_by([m], desc: m.id)
    |> paginate(page)
    |> preload(:transcript)
    |> Repo.all()
  end

  def count_messages(search \\ nil) do
    Message
    |> join(:left, [m], t in assoc(m, :transcript), as: :transcript)
    |> search_messages(search)
    |> Repo.aggregate(:count)
  end

  def get_message!(id), do: Repo.get!(Message, id) |> Repo.preload(:transcript)
  def change_message(%Message{} = m, attrs \\ %{}), do: Message.changeset(m, attrs)
  def create_message(attrs), do: %Message{} |> Message.changeset(attrs) |> Repo.insert()

  def update_message(%Message{} = m, attrs),
    do: m |> Message.update_changeset(attrs) |> Repo.update()

  def delete_message(%Message{} = m), do: Repo.delete(m)

  defp search_messages(query, nil), do: query
  defp search_messages(query, ""), do: query
  defp search_messages(query, s), do: where(query, [m], ilike(m.text, ^"%#{s}%"))

  # --- StreamSettings ---

  def list_stream_settings(search \\ nil, page \\ 1) do
    StreamSettings
    |> join(:left, [s], u in assoc(s, :user), as: :user)
    |> search_by_user(search)
    |> order_by([s], asc: s.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_stream_settings(search \\ nil) do
    StreamSettings
    |> join(:left, [s], u in assoc(s, :user), as: :user)
    |> search_by_user(search)
    |> Repo.aggregate(:count)
  end

  def get_stream_settings!(id), do: Repo.get!(StreamSettings, id) |> Repo.preload(:user)

  def change_stream_settings(%StreamSettings{} = s, attrs \\ %{}),
    do: StreamSettings.changeset(s, attrs)

  def create_stream_settings(attrs),
    do: %StreamSettings{} |> StreamSettings.create_changeset(attrs) |> Repo.insert()

  def update_stream_settings(%StreamSettings{} = s, attrs),
    do: s |> StreamSettings.update_changeset(attrs) |> Repo.update()

  def delete_stream_settings(%StreamSettings{} = s), do: Repo.delete(s)

  # --- TranslateLanguage ---

  def list_translate_languages(search \\ nil, page \\ 1) do
    TranslateLanguage
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_by_user(search)
    |> order_by([t], desc: t.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_translate_languages(search \\ nil) do
    TranslateLanguage
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_by_user(search)
    |> Repo.aggregate(:count)
  end

  def get_translate_language!(id), do: Repo.get!(TranslateLanguage, id) |> Repo.preload(:user)

  def change_translate_language(%TranslateLanguage{} = t, attrs \\ %{}),
    do: TranslateLanguage.changeset(t, attrs)

  def create_translate_language(attrs),
    do: %TranslateLanguage{} |> TranslateLanguage.changeset(attrs) |> Repo.insert()

  def update_translate_language(%TranslateLanguage{} = t, attrs),
    do: t |> TranslateLanguage.update_changeset(attrs) |> Repo.update()

  def delete_translate_language(%TranslateLanguage{} = t), do: Repo.delete(t)

  # --- EventsubSubscription ---

  def list_eventsub_subscriptions(search \\ nil, page \\ 1) do
    EventsubSubscription
    |> join(:left, [e], u in assoc(e, :user), as: :user)
    |> search_eventsub(search)
    |> order_by([e], desc: e.id)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_eventsub_subscriptions(search \\ nil) do
    EventsubSubscription
    |> join(:left, [e], u in assoc(e, :user), as: :user)
    |> search_eventsub(search)
    |> Repo.aggregate(:count)
  end

  def get_eventsub_subscription!(id),
    do: Repo.get!(EventsubSubscription, id) |> Repo.preload(:user)

  def change_eventsub_subscription(%EventsubSubscription{} = e, attrs \\ %{}),
    do: EventsubSubscription.changeset(e, attrs)

  def create_eventsub_subscription(attrs),
    do: %EventsubSubscription{} |> EventsubSubscription.changeset(attrs) |> Repo.insert()

  def update_eventsub_subscription(%EventsubSubscription{} = e, attrs),
    do: e |> EventsubSubscription.changeset(attrs) |> Repo.update()

  def delete_eventsub_subscription(%EventsubSubscription{} = e), do: Repo.delete(e)

  defp search_eventsub(query, nil), do: query
  defp search_eventsub(query, ""), do: query

  defp search_eventsub(query, s),
    do: where(query, [e, user: u], ilike(e.type, ^"%#{s}%") or ilike(u.username, ^"%#{s}%"))

  # --- UserToken ---

  def list_user_tokens(search \\ nil, page \\ 1) do
    UserToken
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_user_tokens(search)
    |> order_by([t], desc: t.inserted_at)
    |> paginate(page)
    |> preload(:user)
    |> Repo.all()
  end

  def count_user_tokens(search \\ nil) do
    UserToken
    |> join(:left, [t], u in assoc(t, :user), as: :user)
    |> search_user_tokens(search)
    |> Repo.aggregate(:count)
  end

  def get_user_token!(id), do: Repo.get!(UserToken, id) |> Repo.preload(:user)
  def delete_user_token(%UserToken{} = t), do: Repo.delete(t)

  defp search_user_tokens(query, nil), do: query
  defp search_user_tokens(query, ""), do: query

  defp search_user_tokens(query, s),
    do: where(query, [t, user: u], ilike(t.context, ^"%#{s}%") or ilike(u.username, ^"%#{s}%"))

  # --- Shared helpers ---

  defp paginate(query, page) when is_integer(page) and page > 0 do
    query |> limit(@page_size) |> offset(^((page - 1) * @page_size))
  end

  defp paginate(query, _), do: paginate(query, 1)

  defp search_by_user(query, nil), do: query
  defp search_by_user(query, ""), do: query

  defp search_by_user(query, s),
    do:
      where(
        query,
        [_, user: u],
        ilike(u.username, ^"%#{s}%") or ilike(u.email, ^"%#{s}%") or ilike(u.uid, ^"%#{s}%")
      )
end

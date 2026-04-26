defmodule StreamClosedCaptionerPhoenix.Bits.Transaction do
  @moduledoc "CRUD for BitsTransaction and Twitch bits processing."

  import Ecto.Query, warn: false

  alias StreamClosedCaptionerPhoenix.Accounts.User
  alias StreamClosedCaptionerPhoenix.AuditLog
  alias StreamClosedCaptionerPhoenix.Bits.Balance
  alias StreamClosedCaptionerPhoenix.Bits.BitsTransaction
  alias StreamClosedCaptionerPhoenix.Bits.BitsTransactionQueries
  alias StreamClosedCaptionerPhoenix.Repo

  def bits_transactions_and_debits_for_user(user_id, offset, limit) do
    base = BitsTransactionQueries.get_bits_transactions_and_debits_for_user(user_id)

    records =
      base
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()

    %{records: records, total_records: Repo.count(base)}
  end

  def list_bits_transactions, do: BitsTransactionQueries.all() |> Repo.all()

  def get_bits_transaction!(id) when is_integer(id) do
    BitsTransactionQueries.with_id(id)
    |> limit(1)
    |> Repo.one!()
  end

  def get_bits_transactions!(%User{} = user) do
    BitsTransactionQueries.with_user_id(user.id)
    |> Repo.all()
  end

  def get_bits_transaction_by(transaction_id) when is_binary(transaction_id) do
    BitsTransactionQueries.with_transaction_id(transaction_id)
    |> limit(1)
    |> Repo.one()
  end

  def create_bits_transaction(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:bits_transactions)
    |> BitsTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def delete_bits_transaction(%BitsTransaction{} = bits_transaction),
    do: Repo.delete(bits_transaction)

  def change_bits_transaction(%BitsTransaction{} = bits_transaction, attrs \\ %{}) do
    BitsTransaction.changeset(bits_transaction, attrs)
  end

  def process_bits_transaction(uid, decoded_token) do
    transaction_info = Map.get(decoded_token, "data")
    transaction_id = Map.get(transaction_info, "transactionId")
    amount = get_in(transaction_info, ["product", "cost", "amount"])

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:validate_amount, fn _repo, _ ->
        if amount == 500, do: {:ok, amount}, else: {:error, :invalid_amount}
      end)
      |> Ecto.Multi.run(:validate_transaction, validate_transaction(transaction_id))
      |> Ecto.Multi.run(:retrieve_channel_user, retrieve_user_by_uid(uid))
      |> Ecto.Multi.run(:retrieve_balance, &retrieve_balance/2)
      |> Ecto.Multi.run(:add_to_balance, add_to_balance(amount))
      |> Ecto.Multi.run(:save_transaction, save_transaction(transaction_info))
      |> Repo.transaction()

    case result do
      {:ok, %{retrieve_channel_user: user, add_to_balance: bits_balance}} ->
        StreamClosedCaptionerPhoenixWeb.Endpoint.broadcast(
          "captions:#{user.id}",
          "transaction",
          %{balance: bits_balance.balance}
        )

        AuditLog.info("bits.credit_applied", %{
          user_id: user.id,
          transaction_id: transaction_id,
          amount: amount,
          balance: bits_balance.balance
        })

      {:error, step, reason, _} ->
        AuditLog.warn("bits.credit_apply_failed", %{
          uid: uid,
          transaction_id: transaction_id,
          step: step,
          reason: AuditLog.format_reason(reason)
        })
    end

    result
  end

  defp validate_transaction(transaction_id) do
    fn _repo, _ ->
      case get_bits_transaction_by(transaction_id) do
        nil -> {:ok, transaction_id}
        _transaction -> {:error, "Transaction #{transaction_id} is already recorded."}
      end
    end
  end

  defp retrieve_user_by_uid(uid) do
    fn _repo, _ ->
      case StreamClosedCaptionerPhoenix.AccountsOauth.get_user_for_provider("twitch", uid) do
        nil -> {:error, "Channel #{uid} not found"}
        user -> {:ok, user}
      end
    end
  end

  defp retrieve_balance(_repo, %{retrieve_channel_user: user}) do
    user = Repo.preload(user, :bits_balance)

    if is_nil(user.bits_balance) do
      {:error, :no_bits_balance}
    else
      {:ok, user.bits_balance}
    end
  end

  defp add_to_balance(amount) do
    fn _repo, %{retrieve_balance: bits_balance} ->
      Balance.update_bits_balance(bits_balance, %{balance: bits_balance.balance + amount})
    end
  end

  defp save_transaction(transaction_info) do
    fn _repo, %{retrieve_channel_user: user} ->
      create_bits_transaction(user, %{
        amount: get_in(transaction_info, ["product", "cost", "amount"]),
        purchaser_uid: get_in(transaction_info, ["userId"]),
        sku: get_in(transaction_info, ["product", "sku"]),
        time: Timex.now(),
        transaction_id: get_in(transaction_info, ["transactionId"])
      })
    end
  end

end

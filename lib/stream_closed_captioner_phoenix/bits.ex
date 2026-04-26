defmodule StreamClosedCaptionerPhoenix.Bits do
  @moduledoc "The Bits context — thin facade delegating to focused sub-contexts."

  alias StreamClosedCaptionerPhoenix.Bits.Balance
  alias StreamClosedCaptionerPhoenix.Bits.Debit
  alias StreamClosedCaptionerPhoenix.Bits.Transaction

  # Balance
  defdelegate list_bits_balances(), to: Balance
  defdelegate get_bits_balance!(id), to: Balance
  defdelegate get_bits_balance_for_user(user), to: Balance
  defdelegate get_bits_balance_by_user_id(user_id), to: Balance
  defdelegate create_bits_balance(user), to: Balance
  defdelegate create_bits_balance(user, attrs), to: Balance
  defdelegate update_bits_balance(bits_balance, attrs), to: Balance
  defdelegate delete_bits_balance(bits_balance), to: Balance
  defdelegate change_bits_balance(bits_balance), to: Balance
  defdelegate change_bits_balance(bits_balance, attrs), to: Balance

  # Debit
  defdelegate list_bits_balance_debits(), to: Debit
  defdelegate list_users_bits_balance_debits(user), to: Debit
  defdelegate get_bits_balance_debit!(id), to: Debit
  defdelegate get_users_bits_balance_debit!(user, id), to: Debit
  defdelegate get_user_active_debit(user_id), to: Debit
  defdelegate get_translation_snapshot(user_id), to: Debit
  defdelegate user_active_debit_exists?(user_id), to: Debit
  defdelegate create_bits_balance_debit(user), to: Debit
  defdelegate create_bits_balance_debit(user, attrs), to: Debit
  defdelegate activate_translations_for(user), to: Debit

  # Transaction
  defdelegate bits_transactions_and_debits_for_user(user_id, offset, limit), to: Transaction
  defdelegate list_bits_transactions(), to: Transaction
  defdelegate get_bits_transaction!(id), to: Transaction
  defdelegate get_bits_transactions!(user), to: Transaction
  defdelegate get_bits_transaction_by(transaction_id), to: Transaction
  defdelegate create_bits_transaction(user), to: Transaction
  defdelegate create_bits_transaction(user, attrs), to: Transaction
  defdelegate delete_bits_transaction(bits_transaction), to: Transaction
  defdelegate change_bits_transaction(bits_transaction), to: Transaction
  defdelegate change_bits_transaction(bits_transaction, attrs), to: Transaction
  defdelegate process_bits_transaction(uid, decoded_token), to: Transaction
end

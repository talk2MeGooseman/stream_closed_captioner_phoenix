defmodule StreamClosedCaptionerPhoenix.Audit do
  @moduledoc """
  The Audit context.
  
  Provides functions for creating and querying audit logs.
  """

  import Ecto.Query, warn: false
  alias StreamClosedCaptionerPhoenix.Repo
  alias StreamClosedCaptionerPhoenix.Audit.AuditLog

  @doc """
  Creates an audit log entry.

  ## Examples

      iex> log_action(user_id: 1, action: "azure_key_updated", resource_type: "user")
      {:ok, %AuditLog{}}

      iex> log_action(user_id: nil, action: "invalid", resource_type: "user")
      {:error, %Ecto.Changeset{}}

  """
  def log_action(attrs) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Logs an Azure key action with optional metadata.
  
  Convenience function that sets resource_type to "azure_key" automatically.
  """
  def log_azure_key_action(user_id, action, metadata \\ %{}) do
    log_action(%{
      user_id: user_id,
      action: action,
      resource_type: "azure_key",
      resource_id: user_id,
      metadata: metadata
    })
  end

  @doc """
  Lists all audit logs for a user.

  ## Examples

      iex> list_user_audit_logs(user_id)
      [%AuditLog{}, ...]

  """
  def list_user_audit_logs(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(al in AuditLog,
      where: al.user_id == ^user_id,
      order_by: [desc: al.created_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Lists audit logs for a specific action.

  ## Examples

      iex> list_audit_logs_by_action("azure_key_used")
      [%AuditLog{}, ...]

  """
  def list_audit_logs_by_action(action, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(al in AuditLog,
      where: al.action == ^action,
      order_by: [desc: al.created_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets recent audit logs across all users.

  ## Examples

      iex> list_recent_audit_logs(limit: 50)
      [%AuditLog{}, ...]

  """
  def list_recent_audit_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(al in AuditLog,
      order_by: [desc: al.created_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Counts audit logs for a user by action.

  ## Examples

      iex> count_user_actions(user_id, "azure_key_used")
      5

  """
  def count_user_actions(user_id, action) do
    from(al in AuditLog,
      where: al.user_id == ^user_id and al.action == ^action,
      select: count(al.id)
    )
    |> Repo.one()
  end
end

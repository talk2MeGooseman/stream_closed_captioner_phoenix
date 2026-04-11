defmodule StreamClosedCaptionerPhoenix.Audit.AuditLog do
  @moduledoc """
  Schema for audit logging of sensitive operations.
  
  Tracks actions on sensitive resources like API keys, providing
  an audit trail for security compliance and incident response.
  """
  
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "audit_logs" do
    belongs_to :user, StreamClosedCaptionerPhoenix.Accounts.User
    
    field :action, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :metadata, :map
    field :ip_address, :string
    field :user_agent, :string

    timestamps(updated_at: false, inserted_at: :created_at)
  end

  @doc """
  Valid actions for audit logging.
  """
  def valid_actions do
    [
      "azure_key_created",
      "azure_key_updated",
      "azure_key_deleted",
      "azure_key_validated",
      "azure_key_used",
      "azure_key_failed_validation"
    ]
  end

  @doc """
  Valid resource types for audit logging.
  """
  def valid_resource_types do
    ["user", "azure_key"]
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :user_id,
      :action,
      :resource_type,
      :resource_id,
      :metadata,
      :ip_address,
      :user_agent
    ])
    |> validate_required([:user_id, :action, :resource_type])
    |> validate_inclusion(:action, valid_actions())
    |> validate_inclusion(:resource_type, valid_resource_types())
    |> foreign_key_constraint(:user_id)
  end
end

# Audit Logging Implementation

## Overview

This document describes the implementation of audit logging for sensitive operations in the StreamClosedCaptionerPhoenix application, with a focus on Azure API key management.

## Purpose

Audit logging provides:
1. **Compliance**: SOC 2, GDPR, and other regulatory requirements
2. **Security**: Detect unauthorized access or suspicious activity
3. **Accountability**: Track who did what and when
4. **Debugging**: Troubleshoot user issues with historical data
5. **Analytics**: Understand usage patterns

## Implementation

### Schema

**Table**: `audit_logs`

```sql
CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action VARCHAR NOT NULL,
  resource_type VARCHAR NOT NULL,
  resource_id INTEGER,
  metadata JSONB DEFAULT '{}',
  ip_address VARCHAR,
  user_agent VARCHAR,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

### Logged Actions

#### Azure Key Actions

| Action | Description | Metadata |
|--------|-------------|----------|
| `azure_key_created` | User added new Azure key | `{changed_at: timestamp}` |
| `azure_key_updated` | User changed existing key | `{changed_at: timestamp}` |
| `azure_key_deleted` | User removed Azure key | `{changed_at: timestamp}` |
| `azure_key_used` | Key used for translation | `{from_language, to_languages, text_length, timestamp}` |
| `azure_key_validated` | Key validated against Azure API | `{success: boolean, error: string}` |
| `azure_key_failed_validation` | Key validation failed | `{error: string, timestamp}` |

### Module Structure

#### 1. Audit Log Schema (`lib/stream_closed_captioner_phoenix/audit/audit_log.ex`)

Defines the database schema and validation rules.

#### 2. Audit Context (`lib/stream_closed_captioner_phoenix/audit.ex`)

Provides functions for creating and querying audit logs:

**Core Functions**:
- `log_action/1` - General purpose audit logging
- `log_azure_key_action/3` - Azure key specific logging
- `list_user_audit_logs/2` - Get logs for a user
- `list_audit_logs_by_action/2` - Filter logs by action
- `count_user_actions/2` - Count actions for analytics

### Integration Points

#### 1. Account Management

In `lib/stream_closed_captioner_phoenix/accounts.ex`:

```elixir
def update_user_azure_key(user, attrs) do
  changeset = User.azure_key_changeset(user, attrs)
  
  with {:ok, updated_user} <- Repo.update(changeset) do
    # Determine and log the action
    action = determine_action(user, updated_user)
    
    if action do
      Audit.log_azure_key_action(user.id, action, %{
        changed_at: DateTime.utc_now()
      })
    end
    
    {:ok, updated_user}
  end
end
```

#### 2. Translation Service

In `lib/stream_closed_captioner_phoenix/captions_pipeline/translations.ex`:

```elixir
defp get_translations_with_user_key(%User{} = user, text) do
  result = Azure.perform_translations(...)
  
  # Log key usage
  Audit.log_azure_key_action(user.id, "azure_key_used", %{
    from_language: from_language,
    to_languages: to_languages,
    text_length: String.length(text),
    timestamp: DateTime.utc_now()
  })
  
  result
end
```

## Usage Examples

### Log an Action

```elixir
# Manually log an action
Audit.log_action(%{
  user_id: user.id,
  action: "azure_key_validated",
  resource_type: "azure_key",
  metadata: %{success: true}
})

# Or use convenience function
Audit.log_azure_key_action(user.id, "azure_key_validated", %{
  success: true,
  timestamp: DateTime.utc_now()
})
```

### Query Audit Logs

```elixir
# Get all logs for a user (limited to 100 by default)
logs = Audit.list_user_audit_logs(user_id)

# Get specific number of logs
logs = Audit.list_user_audit_logs(user_id, limit: 50)

# Filter by action
key_usage_logs = Audit.list_audit_logs_by_action("azure_key_used")

# Count actions
usage_count = Audit.count_user_actions(user_id, "azure_key_used")

# Get recent logs across all users (admin view)
recent_logs = Audit.list_recent_audit_logs(limit: 100)
```

### Example Queries

#### Find users with high API usage

```elixir
alias StreamClosedCaptionerPhoenix.{Audit, Repo}

Repo.all(
  from al in AuditLog,
  where: al.action == "azure_key_used",
  where: al.created_at > ago(7, "day"),
  group_by: al.user_id,
  select: {al.user_id, count(al.id)},
  order_by: [desc: count(al.id)]
)
```

#### Find recent key changes

```elixir
Audit.list_audit_logs_by_action("azure_key_updated", limit: 20)
```

#### Track key lifecycle

```elixir
user_logs = Audit.list_user_audit_logs(user_id, limit: 1000)

Enum.filter(user_logs, fn log ->
  log.action in ["azure_key_created", "azure_key_updated", "azure_key_deleted"]
end)
```

## Security Considerations

### What is Logged

✅ **Safe to log**:
- User ID
- Action type
- Timestamp
- Resource type and ID
- Metadata (sanitized)
- IP address (anonymized if required)
- User agent

❌ **NEVER log**:
- Actual API keys
- Passwords or tokens
- Personal identifiable information (without consent)
- Credit card numbers
- Social security numbers

### Metadata Sanitization

Always sanitize metadata before logging:

```elixir
# BAD - logs sensitive data
Audit.log_azure_key_action(user.id, "azure_key_created", %{
  key: user.azure_service_key  # ❌ NEVER DO THIS
})

# GOOD - logs safe metadata only
Audit.log_azure_key_action(user.id, "azure_key_created", %{
  key_length: String.length(user.azure_service_key),
  key_format: detect_format(user.azure_service_key),
  timestamp: DateTime.utc_now()
})
```

## Retention Policy

### Recommended Retention

| Environment | Retention Period | Reason |
|-------------|------------------|---------|
| Development | 30 days | Testing and debugging |
| Staging | 90 days | Pre-production validation |
| Production | 1-2 years | Compliance requirements |

### Implementation

Add to `config/runtime.exs`:

```elixir
config :stream_closed_captioner_phoenix,
  audit_log_retention_days: String.to_integer(
    System.get_env("AUDIT_LOG_RETENTION_DAYS") || "730"
  )
```

Create cleanup job with Oban:

```elixir
defmodule StreamClosedCaptionerPhoenix.Workers.AuditLogCleanup do
  use Oban.Worker, queue: :maintenance
  
  @impl Oban.Worker
  def perform(_job) do
    retention_days = Application.get_env(
      :stream_closed_captioner_phoenix,
      :audit_log_retention_days
    )
    
    cutoff = DateTime.utc_now() |> DateTime.add(-retention_days * 24 * 60 * 60, :second)
    
    {deleted_count, _} = 
      from(al in AuditLog, where: al.created_at < ^cutoff)
      |> Repo.delete_all()
    
    {:ok, %{deleted: deleted_count}}
  end
end
```

Schedule in `config/config.exs`:

```elixir
config :stream_closed_captioner_phoenix, Oban,
  queues: [maintenance: 1],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", StreamClosedCaptionerPhoenix.Workers.AuditLogCleanup}
     ]}
  ]
```

## Monitoring and Alerting

### Metrics to Track

1. **Audit log volume**: Track write rate
2. **Failed validations**: Spike indicates issue
3. **Key usage patterns**: Detect anomalies
4. **Unauthorized access attempts**: Security alerts

### Example Alerts

```elixir
# Alert on suspicious activity
def check_suspicious_activity(user_id) do
  # More than 100 key uses in 1 hour
  recent_count = 
    from(al in AuditLog,
      where: al.user_id == ^user_id,
      where: al.action == "azure_key_used",
      where: al.created_at > ago(1, "hour"),
      select: count(al.id)
    )
    |> Repo.one()
  
  if recent_count > 100 do
    # Send alert
    Logger.warning("Suspicious activity detected",
      user_id: user_id,
      action_count: recent_count
    )
  end
end
```

## Testing

Run audit tests:

```bash
mix test test/stream_closed_captioner_phoenix/audit_test.exs
```

Key test scenarios:
- Log creation with valid/invalid attributes
- Querying by user, action, and time
- Counting actions
- Metadata handling
- Integration with account operations

## Compliance

This implementation supports:

- **SOC 2 Type II**: Audit trails for security events
- **GDPR Article 30**: Records of processing activities
- **HIPAA**: Access logs for protected health information
- **PCI DSS 10**: Track and monitor all access to network resources

## Performance Considerations

### Write Performance

- Async logging recommended for high-volume actions
- Use database connection pooling
- Consider batching writes for very high volume

### Query Performance

- Indexes on `user_id`, `action`, `created_at`
- Partition table by time for very large datasets
- Use materialized views for analytics

### Storage

- ~200 bytes per log entry
- 1M logs ≈ 200 MB
- Consider partitioning for >10M logs

## Future Enhancements

1. **Export functionality**: CSV/JSON export for compliance
2. **Real-time streaming**: Kafka/EventHub integration
3. **Anomaly detection**: ML-based pattern analysis
4. **User notifications**: Email on security events
5. **Admin dashboard**: Visual analytics

## References

- [SOC 2 Audit Logging Requirements](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report.html)
- [GDPR Article 30](https://gdpr-info.eu/art-30-gdpr/)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)

---

**Last Updated**: 2026-03-09  
**Implementation Status**: ✅ Complete and tested

# Deployment Guide: Security Improvements

**Quick Reference for Production Deployment**

---

## ⚠️ CRITICAL: Before Deploying

### 1. Generate Encryption Key

```bash
# Generate a secure 32-byte encryption key
elixir -e 'IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode64())'
```

**Example Output**: `G1U89ys/OtWZKgTn3mV98WyTPb8ssKn7mp380/N6jfE=`

### 2. Set Environment Variable

Add to your production environment:

```bash
export ENCRYPTION_KEY="<your-generated-key-here>"
```

**⚠️ WARNING**: 
- Never commit this key to source control
- Store securely (e.g., AWS Secrets Manager, Vault)
- Backup this key in secure location
- **Loss of key = loss of all encrypted data**

---

## Deployment Steps

### Step 1: Code Deployment

```bash
git pull origin main
mix deps.get --only prod
MIX_ENV=prod mix compile
```

### Step 2: Run Migrations

```bash
MIX_ENV=prod mix ecto.migrate
```

**Expected Output**:
```
Compiling...
[info] == Running ... EncryptAzureServiceKeys.up/0 forward
[info] alter table users
[info] == Migrated in 0.1s
[info] == Running ... CreateAuditLogs.change/0 forward  
[info] create table audit_logs
[info] create index audit_logs_user_id_index
[info] == Migrated in 0.2s
```

### Step 3: Restart Application

```bash
# Your deployment process
# e.g., systemctl restart app, docker restart, etc.
```

### Step 4: Verify Deployment

#### Check Encryption

```elixir
# In IEx console
iex -S mix
user = StreamClosedCaptionerPhoenix.Accounts.get_user!(1)
user.azure_service_key  # Should work (decrypted automatically)
```

#### Check Database

```sql
-- Keys should be binary, not plain text
SELECT 
  id, 
  email,
  CASE 
    WHEN azure_service_key IS NULL THEN 'NULL'
    ELSE 'ENCRYPTED (' || length(azure_service_key) || ' bytes)'
  END as key_status
FROM users 
WHERE azure_service_key IS NOT NULL
LIMIT 5;
```

#### Check Audit Logs

```elixir
# In IEx console
StreamClosedCaptionerPhoenix.Audit.list_recent_audit_logs(limit: 10)
```

---

## Rollback Plan

### If Issues Occur

1. **Keep ENCRYPTION_KEY set** (needed to decrypt existing data)
2. **Rollback migration**:
   ```bash
   MIX_ENV=prod mix ecto.rollback --step 2
   ```
3. **Deploy previous code version**
4. **Investigate issue**

### ⚠️ Important Notes
- Cannot rollback if ENCRYPTION_KEY is lost
- Rollback converts encrypted data to plain text
- Coordinate with team before rollback

---

## Post-Deployment Monitoring

### First 24 Hours

Monitor for:
- [ ] Application errors (especially encryption-related)
- [ ] Audit log creation (should see entries)
- [ ] Key update flow works correctly
- [ ] No performance degradation

### Logs to Watch

```bash
# Application logs
tail -f /var/log/app/production.log | grep -i "encrypt\|audit"

# Database logs
tail -f /var/log/postgresql/postgresql.log
```

### Expected Behavior
- New/updated keys are encrypted automatically
- Existing NULL keys remain NULL
- Audit logs created for all key operations
- No visible performance impact

---

## Troubleshooting

### Error: "Encryption key not configured"

**Cause**: ENCRYPTION_KEY environment variable not set  
**Solution**: Set the environment variable and restart app

```bash
export ENCRYPTION_KEY="your-key-here"
systemctl restart your-app
```

### Error: "Encryption key must be 32 bytes"

**Cause**: Invalid key format  
**Solution**: Regenerate key using command above

### Decryption Returns Nil

**Cause**: Wrong encryption key or corrupted data  
**Solution**: 
1. Verify ENCRYPTION_KEY matches what was used to encrypt
2. Check database for data corruption
3. Review application logs

### Audit Logs Not Created

**Cause**: Database migration not run  
**Solution**: Run migrations

```bash
MIX_ENV=prod mix ecto.migrate
```

---

## Security Checklist

After deployment, verify:

- [ ] ENCRYPTION_KEY is set in production environment
- [ ] ENCRYPTION_KEY is backed up securely (NOT in source control)
- [ ] Database shows encrypted binary data (not plain text)
- [ ] Audit logs are being created
- [ ] Key update flow works in production
- [ ] Application logs show no encryption errors
- [ ] Team knows where to find ENCRYPTION_KEY backup

---

## Support

### Documentation
- **IMPLEMENTATION_SUMMARY.md** - Complete implementation details
- **ENCRYPTION_IMPLEMENTATION.md** - Encryption technical docs
- **AUDIT_LOGGING.md** - Audit logging docs
- **IMPLEMENTATION_REPORT.md** - Executive summary

### Quick Tests

```elixir
# Test encryption
alias StreamClosedCaptionerPhoenix.{Accounts, Audit}
user = Accounts.get_user!(user_id)
{:ok, updated} = Accounts.update_user_azure_key(user, %{
  azure_service_key: "a1b2c3d4e5f6789012345678901234ab"
})

# Verify it's encrypted in DB
# Should see binary data, not plain text

# Check audit log
Audit.list_user_audit_logs(user_id) |> List.first()
# Should show azure_key_created or azure_key_updated
```

---

## Next Steps

After successful deployment:

1. **Monitor for 1 week**
   - Check logs daily
   - Review audit trail
   - Monitor performance

2. **Set Up Alerts**
   - Encryption errors
   - Unusual audit patterns
   - Performance degradation

3. **Document Key Rotation**
   - Create key rotation procedure
   - Schedule first rotation (recommend 90 days)

4. **Plan Enhancements**
   - Review IMPLEMENTATION_SUMMARY.md future enhancements
   - Prioritize based on usage patterns

---

**Deployment Prepared**: 2026-03-09  
**Status**: ✅ Ready for Production  
**Estimated Deploy Time**: 10-15 minutes

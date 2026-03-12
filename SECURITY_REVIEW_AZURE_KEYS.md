# Azure API Key Storage - Security Review & Recommendations

## Executive Summary

**SEVERITY: HIGH - Multiple critical security vulnerabilities identified**

The current implementation stores user-provided Azure Cognitive Services API keys in **plain text** in the PostgreSQL database with minimal security controls. This presents significant security, compliance, and operational risks that must be addressed before production deployment.

---

## 1. CRITICAL SECURITY RISKS (Immediate Action Required)

### 🔴 CRITICAL: Plain Text Storage in Database
**Risk Level**: CRITICAL  
**CVSS Score**: 8.5 (High)

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/accounts/user.ex:11
field :azure_service_key, :string
```

- API keys stored as plain text in `users.azure_service_key` field
- No encryption at rest (beyond database-level encryption if configured)
- Keys directly readable by anyone with database access

**Attack Vectors:**
1. **Database Compromise**: Single breach exposes all user API keys
2. **SQL Injection**: Any SQL injection vulnerability leaks keys
3. **Backup Exposure**: Database backups contain plain text keys
4. **Insider Threat**: DBAs, developers, support staff can read keys
5. **Log Leakage**: Database query logs may expose keys
6. **Development/Staging Copies**: Keys copied to non-production environments

**Business Impact:**
- Users' Azure credits can be stolen/abused
- Financial liability for unauthorized API usage
- Reputational damage and loss of trust
- Potential legal liability for negligent security practices

---

### 🔴 CRITICAL: No Protection in Inspect/JSON Serialization
**Risk Level**: CRITICAL

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/accounts/user.ex:5-7
@derive {Inspect, except: [:password, :encrypted_password]}
@derive {Jason.Encoder, only: [:email, :provider, :uid, :username, ...]}
```

**Issues:**
1. `azure_service_key` **IS NOT** excluded from Inspect protocol
2. Keys will appear in crash dumps (`erl_crash.dump` found in repo root)
3. Keys may appear in IEx sessions, logs, and error traces
4. While not in Jason.Encoder `only` list, defensive exclusion recommended

---

### 🔴 CRITICAL: API Keys May Be Logged to NewRelic
**Risk Level**: CRITICAL

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/services/azure/cognitive.ex:57
NewRelic.add_attributes(translate: %{from: from_language, to: to_languages, text: text})
```

**Issues:**
1. While keys not directly logged, HTTP errors may expose them
2. NewRelic traces HTTP requests which include headers
3. No explicit header scrubbing configured
4. Error stack traces may include `api_key` variable

---

### 🟠 HIGH: No Error Handling - Keys May Leak in Exceptions
**Risk Level**: HIGH

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/services/azure/cognitive.ex:59-64
[translations] =
  "https://guzman.codes/azure_proxy/translate"
  |> encode_url_and_params(params)
  |> HTTPoison.post!(body, headers)  # ❌ Using post! (raises exceptions)
  |> Map.fetch!(:body)
  |> Jason.decode!()
```

**Issues:**
1. Uses `post!` which raises exceptions (not `post` which returns tuples)
2. No `rescue` or error handling around API calls
3. Exception messages may include `headers` with API keys
4. Exceptions propagate to error tracking systems (NewRelic)

**Example Exception:**
```
** (HTTPoison.Error) :timeout
    Headers: [{"Ocp-Apim-Subscription-Key", "user-secret-key-12345"}]
```

---

### 🟠 HIGH: Keys Transmitted Through Third-Party Proxy
**Risk Level**: HIGH

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/services/azure/cognitive.ex:60
"https://guzman.codes/azure_proxy/translate"
```

**Issues:**
1. API keys sent to custom proxy server (`guzman.codes`)
2. Unknown security posture of proxy infrastructure
3. Proxy can log/intercept all API keys
4. Single point of failure for key compromise
5. No documentation on proxy security controls

---

### 🟠 HIGH: No Access Control or Audit Logging
**Risk Level**: HIGH

**Current State:**
- ❌ No logging when keys are created/updated/deleted
- ❌ No audit trail of key usage
- ❌ No rate limiting on key updates
- ❌ No IP whitelisting or geographic restrictions
- ❌ No alerting on suspicious key usage patterns
- ❌ Cannot detect compromised keys

---

### 🟡 MEDIUM: Input Validation Insufficient
**Risk Level**: MEDIUM

**Current Implementation:**
```elixir
# lib/stream_closed_captioner_phoenix/accounts/user.ex:225-229
key when is_binary(key) and byte_size(key) >= 10 and byte_size(key) <= 256 ->
  changeset
```

**Issues:**
1. Only validates length, not format
2. Accepts any string between 10-256 characters
3. No validation that it's a valid Azure key format
4. No check for test/revoked keys
5. No validation against Azure API before storage

---

## 2. COMPLIANCE & REGULATORY CONCERNS

### GDPR (General Data Protection Regulation)
**Status**: ⚠️ POTENTIAL NON-COMPLIANCE

**Issues:**
1. **Art. 32 - Security of Processing**: Plain text storage fails "appropriate security" requirement
2. **Data Breach Notification**: No ability to identify which users affected
3. **Right to Erasure**: Keys may remain in backups after user deletion

**Recommendation**: Implement encryption before EU user deployment

---

### SOC 2 (Service Organization Control 2)
**Status**: ⚠️ FAILS MULTIPLE CRITERIA

**Failed Controls:**
- **CC6.1 - Logical Access**: No encryption of sensitive authentication credentials
- **CC6.6 - Encryption**: No encryption of sensitive data at rest
- **CC7.2 - System Monitoring**: No monitoring of key access/usage
- **CC6.8 - Audit Logging**: No audit trail for key operations

**Impact**: Cannot achieve SOC 2 certification with current implementation

---

### Industry Standards
**Status**: ❌ NON-COMPLIANT

- **OWASP Top 10 - A02:2021**: Cryptographic Failures
- **CWE-312**: Cleartext Storage of Sensitive Information
- **NIST 800-53 SC-28**: Protection of Information at Rest - Not Met

---

## 3. IMMEDIATE FIXES REQUIRED (Priority Order)

### P0 - BLOCKER (Must fix before production)

#### Fix 1: Exclude Keys from Inspect Protocol
**Effort**: 5 minutes  
**Impact**: HIGH


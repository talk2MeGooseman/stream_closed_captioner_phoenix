# Trinity Decision: Security Audit Log Events

Date: 2026-04-19

## Decision

Implement security audit events through a lightweight shared module using Logger plus Telemetry instead of a new persistence layer.

## Rationale

- Keeps runtime behavior unchanged and avoids introducing dependencies or migrations.
- Provides immediate observability with structured events and warning-level failure visibility.
- Supports testability by asserting emitted telemetry events in DataCase/ConnCase tests.

## Event Contract

- Telemetry event: `[:stream_closed_captioner_phoenix, :audit_log]`
- Metadata includes:
  - `event` (string)
  - `level` (`:info` or `:warning`)
  - contextual non-secret fields (`user_id`, `provider`, `amount`, `reason`, etc.)

## Security Constraint

Audit metadata redacts sensitive keys (`access_token`, `refresh_token`, `token`, `password`, `current_password`, `encrypted_password`, `azure_service_key`).

## Scope Applied

- Bits debit/credit and translation activation
- Password change/reset + reset instruction issuance
- OAuth linking/unlinking
- User settings entry points for change/unlink actions
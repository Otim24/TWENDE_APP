# SECURITY AUDIT (Resolved & Hardened)

> [!NOTE]
> All backend, passenger app, and conductor app security items identified in the project audit have been remediated and verified via integration tests (`backend/tests/test_remediation.py`) and Flutter unit/widget tests (`passenger_app/test/widget_test.dart`, `conductor_app/test/widget_test.dart`).

## Summary Table

| Severity | Open Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |

---

## Remediated Backend Vulnerabilities

- **[FIXED] Unauthenticated WebSocket GPS Broadcast (`backend/app/api/v1/tracking.py`)**: Added JWT validation (`?token=<jwt>` or `Authorization: Bearer <jwt>`) on WebSocket connect, enforced `UserRole.CONDUCTOR` for broadcasting GPS updates, and validated coordinates with `LocationUpdatePayload` (`lat in [-90, 90]`, `lng in [-180, 180]`).
- **[FIXED] Wallet Double-Spend & Seat Overbooking Race Conditions (`backend/app/api/v1/bookings.py`, `backend/app/api/v1/conductor.py`, `backend/app/api/v1/wallet.py`)**: Wrapped all seat reservation, ticket verification, wallet deposit, and wallet debit flows in `async with in_transaction():` with `select_for_update()` row-level locks on `Trip`, `Booking`, and `Wallet`.
- **[FIXED] Concurrency Race Condition in User & Wallet Creation (`backend/app/api/v1/auth.py`, `backend/app/api/v1/conductor.py`)**: Moved `User` lookup, creation, and `Wallet.get_or_create` inside `async with in_transaction():` with `select_for_update()` and `IntegrityError` recovery.
- **[FIXED] OTP Brute-Force, Non-Atomic Consumption & Role Escalation (`backend/app/api/v1/auth.py`)**: Added a 60-second Redis cooldown on `/otp/request`, a 5-attempt lockout counter (`otp_attempts:{phone}`) on `/otp/verify`, constant-time comparison (`secrets.compare_digest`), immediate OTP deletion on match, and restricted OTP login strictly to `UserRole.PASSENGER` (`403 Forbidden` for `CONDUCTOR`/`ADMIN`).
- **[FIXED] Secret Serialization, Plaintext DB URL Logging & Public `/sentry-debug` (`backend/app/core/config.py`, `backend/app/main.py`, `backend/debug_db.py`)**: Excluded `DATABASE_URL`, `SECRET_KEY`, and `SENTRY_DSN` from `Settings` `repr()` and `model_dump()` via `Field(repr=False, exclude=True)`, redacted DB passwords in `debug_db.py`, removed `/sentry-debug`, gated Sentry init on `settings.SENTRY_DSN` with `send_default_pii=False`, and added `CORSMiddleware`.

---

## Remediated Mobile Client Hardening Items

- **[FIXED] Externalized Sentry DSNs (`passenger_app/lib/main.dart`, `conductor_app/lib/main.dart`, `core/api/api_endpoints.dart`)**: Removed hardcoded Sentry DSN literals from both Flutter apps. Sentry now initializes only when `SENTRY_DSN` is non-empty in `.env`, with `sendDefaultPii = false`.
- **[FIXED] Bearer JWT Injection, 401 Session Handling & Log Redaction (`passenger_app/lib/core/api/api_client.dart`, `conductor_app/lib/core/api/api_client.dart`)**: Both Flutter Dio clients now attach `Authorization: Bearer <token>`, handle `401 Unauthorized` cleanly, and redact `access_token`, `qr_code_data`, `password`, and `code` fields in debug logs.

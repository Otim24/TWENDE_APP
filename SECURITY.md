# SECURITY AUDIT (Active Findings)

> [!NOTE]
> All previously documented security issues (such as plaintext passwords, unauthenticated conductor endpoints, and exposed database secrets) have been successfully mitigated. This document tracks newly discovered security vulnerabilities found during the recent in-depth audit.

## Summary Table

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 2 |

---

## Authentication & Authorization

### HIGH: Concurrency Race Condition in User Creation
- **Location**: `backend/app/api/v1/auth.py`
- **Vulnerability**: Within `verify_otp`, the lookup `user = await User.get_or_none(phone=payload.phone)` is performed *outside* the `async with in_transaction():` block. If two concurrent requests verify the same OTP simultaneously, both will see `user` as `None` and proceed to create a new User.
- **Danger**: This triggers a database `IntegrityError` due to the unique constraint on the `phone` column, crashing the request and potentially leaving orphaned `Wallet` records if not handled cleanly.
- **Fix**: Move the `get_or_none` query inside the transaction block and use an atomic "get or create" paradigm, or employ database locks (`select_for_update()`).

---

## Business Logic Vulnerabilities

### HIGH: Missing Wallet Funding Endpoints
- **Location**: `backend/app/api/v1/wallet.py` & Passenger App UI
- **Vulnerability**: The passenger mobile application contains a UI path (`/wallet/deposit -> DepositScreen`) encouraging users to deposit funds. However, the backend completely lacks a corresponding secure endpoint to process external payment gateway (MOMO/Card) callbacks or direct deposit requests.
- **Danger**: The `sell_ticket` API explicitly checks `wallet.balance < ticket_price`, but there is mathematically no way for a passenger to increase their balance. This breaks the core functionality of remote booking.
- **Fix**: Implement a secure `/wallet/deposit/callback` endpoint that accepts and cryptographically verifies webhooks from the payment provider before minting a `TransactionType.DEPOSIT`.

---

## Mobile App Security

### MEDIUM: Hardcoded Sentry DSNs
- **Location**: `passenger_app/lib/main.dart` and `conductor_app/lib/main.dart`
- **Vulnerability**: Both apps hardcode the Sentry DSN directly into the `SentryFlutter.init` block.
  `options.dsn = 'https://6aa30fe8a75ef59b37d0a3c8f33c180c@o4511531098832896.ingest.us.sentry.io/4511531149950976';`
- **Danger**: While DSNs are generally public-facing, hardcoding them prevents dynamic environment switching (Staging vs. Production) and clutters production error logs with local development exceptions.
- **Fix**: Extract the DSN to the `.env` file via `flutter_dotenv`.

### MEDIUM: Incomplete Environment Security
- **Location**: `conductor_app`
- **Vulnerability**: Unlike the `passenger_app`, the conductor app's `pubspec.yaml` lacks the `flutter_dotenv` package, meaning it does not have a standardized mechanism to load `.env` variables.
- **Danger**: Developers are forced to hardcode API URLs and secrets directly into Dart files, increasing the risk of accidental exposure in version control.
- **Fix**: Install `flutter_dotenv` in the conductor app, add `.env` to assets in `pubspec.yaml`, and load it in `main.dart` before `runApp()`.

---

## Recommendations
1. **Immediate Action**: Address the concurrency flaw in `auth.py` by ensuring database locks during the `get_or_create` logic.
2. **Short Term**: Implement the webhook infrastructure for Mobile Money (MOMO) deposits to ensure the passenger app is functional.
3. **Long Term**: Standardize environment configuration across *all* frontend apps to prevent hardcoded URLs or DSNs.

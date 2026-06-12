# BUGS & ANTI-PATTERNS

## Summary Table

| Severity | Count |
|---|---|
| CRITICAL | 2 |
| HIGH | 5 |
| MEDIUM | 4 |
| LOW | 3 |

## Backend Issues

### CRITICAL
- **Missing Authentication on Conductor Endpoints**: `backend/app/api/v1/conductor.py`. `verify_ticket`, `sell_ticket`, `trips`, and `manifest` routes lack any authentication dependency (`Depends(get_current_user)`). Any unauthenticated user can access these endpoints and consume tickets. Fix: Add authentication validation dependency.
- **Plain Text Passwords**: `backend/app/api/v1/auth.py` (lines 95-97). The `login` endpoint directly compares `user.password_hash != payload.password`. Passwords are being stored and verified in plain text. Fix: Use `passlib.context` with bcrypt for hashing and verification.

### HIGH
- **Broken Payment Flow**: `backend/app/api/v1/conductor.py` (line 89). `sell_ticket` assumes cash/MOMO was successful locally and directly issues a `Booking` with `BookingStatus.PAID` without verifying the actual payment or deducting from the Wallet balance.
- **Wallet Schema Mismatch**: `backend/app/models/wallet_model.py` lacks `currency` and `status` fields, but `backend/fix_db.py` (lines 23-24) defines these fields in the actual SQL table. Fix: Add `currency = fields.CharField(max_length=3, default="UGX")` and `status = fields.CharField(max_length=8, default="ACTIVE")` to the Tortoise model.
- **Duplicate Return Statement**: `backend/app/api/v1/auth.py` (lines 75-76). `return {"access_token": access_token, "token_type": "bearer"}` is duplicated. Fix: Remove line 76.

### MEDIUM
- **N+1 Query Issue**: `backend/app/api/v1/conductor.py` (lines 123-124). Inside the `get_trips` loop, `await t.fetch_related("bus", "route", "bookings")` is called for each trip individually in a loop instead of efficiently joining. Fix: Use `prefetch_related("bus", "route", "bookings")` in the initial `Trip.filter()` query.

## Flutter Issues

### HIGH
- **Hardcoded API Endpoints**: `passenger_app/lib/core/api/api_endpoints.dart` (lines 6, 11) contains hardcoded `127.0.0.1:8000`. `ip_info.txt` contains `192.168.100.19`. These will break on physical devices or production environments. Fix: Load URLs dynamically from a `.env` file via `flutter_dotenv`.
- **Missing Sentry Initialisation Cleanup**: Both `passenger_app/lib/main.dart` (line 37) and `conductor_app/lib/main.dart` (line 20) contain `await Sentry.captureException(Exception('This is a sample exception.'));`. This will send a false error to Sentry on every app launch. Fix: Remove these lines.

### MEDIUM
- **Empty Routes in App**: `passenger_app/lib/main.dart` has an empty implementation for `/profile` using a basic `Scaffold` placeholder.
- **TODO Debt**: Various `TODO`s exist throughout the app:
  - `deposit_screen.dart` line 90: Payment Logic missing.
  - `otp_screen.dart` line 128: Resend OTP missing.
  - `account_screen.dart` line 74: Logout logic missing.
  - `CMakeLists.txt` and `build.gradle` files mention updating application IDs and signing configs.

### LOW
- **Missing Null Safety & Exception Handlers on API**: `passenger_app/lib/features/booking/data/booking_repository.dart` catches DioExceptions, but other parts of the app might not be doing thorough safety checks on API responses (e.g. empty lists vs nulls).

## Infrastructure Issues

### CRITICAL
- **Production Secrets in Source Code**: The `.env` file contains `SECRET_KEY=change_this_secret_key` and is committed to the repository because `.gitignore` only ignores `data/`. Fix: Add `.env` to `.gitignore` and rotate the `SECRET_KEY` immediately.

### MEDIUM
- **Migration Debt**: The presence of `fix_db.py`, `fix_schema.py`, and `fix_schema_remaining.py` indicates a broken migration strategy. `fix_schema.py` adds a `status` column to `trips` manually. Fix: Adopt `aerich` (already in `pyproject.toml`) for a structured migration system and remove these scripts.
- **No Redis Error Handling**: `backend/app/api/v1/auth.py` connects to Redis but does not handle connection dropouts gracefully. If Redis fails, OTP requests will crash with a 500 error.

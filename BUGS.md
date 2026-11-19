# BUGS & ANTI-PATTERNS (Active Audit Findings)

> [!NOTE]
> All previously documented bugs and newly discovered backend audit findings have been resolved and verified via automated integration tests (`backend/tests/test_remediation.py`).

## Summary Table

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |

---

## Resolved Issues

### Backend Issues

- **[FIXED] Plaintext Seed Password & Naïve Datetime in `seed_conductor.py`:** `backend/seed_conductor.py` & `backend/app/api/v1/auth.py`. Conductor seed password `"1234"` is now hashed via `get_password_hash`, trip times use `datetime.now(timezone.utc)`, and `/api/v1/auth/login` safely returns `400 Invalid credentials` on empty or malformed hashes instead of crashing with `500 UnknownHashError`.
- **[FIXED] Missing Passenger Booking & Wallet Deposit Endpoints:** `backend/app/api/v1/bookings.py` & `backend/app/api/v1/wallet.py`. Added `POST /api/v1/wallet/deposit` and `POST /api/v1/bookings` with `Decimal` arithmetic, row-level locking (`select_for_update()`), and HMAC QR generation.
- **[FIXED] Out-of-Bounds Seat Numbers & Cancelled Seat Re-Booking:** `backend/app/api/v1/bookings.py`, `backend/app/api/v1/conductor.py`, & `backend/app/models/bus_model.py`. Standardized bus capacity via `Bus.get_valid_seats()`, validated seat bounds, clamped `available_seats`, added `booked_seats` and `seat_layout` to `GET /api/v1/bookings/{trip_id}`, and enabled in-place re-booking of `CANCELLED`/`LOCKED` rows.
- **[FIXED] Broken Manual Boarding & QR Replay Race in `verify_ticket`:** `backend/app/api/v1/conductor.py`. `POST /api/v1/conductor/verify_ticket` now supports both HMAC QR strings and `booking_id` (or numeric `ticket_data`) for manual boarding, locks the booking row via `select_for_update()`, validates active trip status, returns the actual `trip.route.name`, and rejects replays with `400`.
- **[FIXED] WebSocket Path Mismatch & Empty `cargo_model` Warning:** `backend/app/api/v1/tracking.py` & `backend/app/core/database.py`. Registered WebSocket tracking on both `/{trip_id}` and `/ws/{trip_id}` and removed the empty `app.models.cargo_model` placeholder from `TORTOISE_ORM`.
- **[FIXED] Nullable `User.full_name` & Missing `PATCH /api/v1/users/me`:** `backend/app/api/v1/users.py`. Made `full_name` optional in `UserResponse` and implemented `PATCH /api/v1/users/me`.
- **[FIXED] Float Default on `Wallet.balance`:** `backend/app/models/wallet_model.py`. Changed `default=0.00` (`float`) to `default=Decimal("0.00")`.
- **[FIXED] Broken QR Ticket Verification:** `backend/app/api/v1/conductor.py`. Parses `TICKET-{trip_id}-{seat_number}:{signature}` and verifies the HMAC signature with `hmac.compare_digest`.
- **[FIXED] Timezone Mishandling in Trip Search:** `backend/app/api/v1/bookings.py`. Uses `.replace(tzinfo=timezone.utc)` for timezone-aware trip filtering.
- **[FIXED] Hardcoded Manifest Mapping Loop:** `backend/app/api/v1/conductor.py`. Uses `Bus.get_valid_seats()` (`seat_layout` JSON when present; sequential fallback).
- **[FIXED] Missing "Available Seats" Calculation:** `backend/app/api/v1/bookings.py`. Subtracts active (`PAID`, `USED`) bookings from bus capacity.

### Flutter App Issues

- **[FIXED] Conductor App Architectural Debt (Routing & `.env`):** `conductor_app/lib/main.dart`, `conductor_app/pubspec.yaml`, & `conductor_app/lib/core/api/api_endpoints.dart`. Migrated to `go_router` and centralized API base URLs into `flutter_dotenv` (`.env`).

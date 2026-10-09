# BUGS & ANTI-PATTERNS (Active Audit Findings)

> [!NOTE]
> All previously documented bugs in this file have been marked as resolved and verified as fixed. This document now tracks newly discovered active issues found during the recent in-depth audit.
> **UPDATE:** All bugs identified in the recent audit have been resolved!

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

- **[FIXED] Broken QR Ticket Verification:** `backend/app/api/v1/conductor.py`. The `verify_ticket` endpoint now correctly parses the `TICKET-{trip_id}-{seat_number}:{signature}` format and verifies the HMAC signature to securely validate tickets.
- **[FIXED] Timezone Mishandling in Trip Search:** `backend/app/api/v1/bookings.py`. The `/search` endpoint now uses `.replace(tzinfo=timezone.utc)` to correctly perform timezone-aware trip filtering.
- **[FIXED] Hardcoded Manifest Mapping Loop:** `backend/app/api/v1/conductor.py`. The manifest generation now checks for a `seat_layout` property on the `Bus` model to support non-sequential seating layouts, falling back to sequential generation only when necessary. 
- **[FIXED] Missing "Available Seats" Calculation:** `backend/app/api/v1/bookings.py`. The `/search` endpoint accurately calculates `available_seats` by subtracting active, paid, and used bookings from the bus's total capacity.

### Flutter App Issues

- **[FIXED] Conductor App Architectural Debt (Routing):** `conductor_app/lib/main.dart`. The conductor app has been migrated to use `go_router` for scalable navigation and deep-linking, resolving the `MaterialApp` direct routing debt. Missing `pubspec.yaml` was also restored.

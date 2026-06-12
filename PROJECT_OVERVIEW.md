# TWENDE Project Overview

## Summary Table

| Category | Status |
|---|---|
| Architecture Components | 4 |
| API Endpoints | 12 |
| Database Models | 6 |

## Architecture

### Components
- **Backend**: FastAPI (Python 3.11). Provides REST API, JWT auth, Tortoise ORM for database models, Redis for OTP caching, and PostgreSQL for persistence. Status: ~60% Done.
- **Passenger App**: Flutter (Dart). Passenger-facing mobile app for ticket booking, wallet deposits, and viewing trips. Status: ~50% Done.
- **Conductor App**: Flutter (Dart). Conductor-facing mobile app for ticket verification, walk-in sales, and manifest viewing. Status: ~40% Done.
- **Admin Dashboard**: Referenced, but no source code directory or implementation details currently present in the repository beyond an empty folder structure. Status: 0% Done.

### Backend API Endpoints (`backend/app/api/v1/`)
| Route | Method | Purpose | Authenticated? |
|---|---|---|---|
| `/otp/request` | POST | Request a 6-digit OTP via SMS | No |
| `/otp/verify` | POST | Verify OTP and register/login user, return JWT | No |
| `/login` | POST | Login with phone & plain text password | No |
| `/verify_ticket` | POST | Verify and consume QR ticket | No (Security Flaw) |
| `/sell_ticket` | POST | Sell a ticket to a walk-in passenger | No (Security Flaw) |
| `/trips` | GET | List available trips for conductors | No (Security Flaw) |
| `/trips/{id}/manifest` | GET | Get passenger manifest for a specific trip | No (Security Flaw) |
| `/my-trips` | GET | List current user's trips | Yes |
| `/search` | GET | Search for trips by origin, destination, and date | No |
| `/{trip_id}` | GET | Get detailed trip info | No |
| `/me` | GET | Get current logged-in user profile | Yes |
| `/balance` | GET | Get current user's wallet balance | Yes |

### Database Schema (Tortoise ORM)
- **User**: Stores phone, password_hash, full_name, and role (PASSENGER, CONDUCTOR, ADMIN).
- **Wallet**: 1-to-1 with User. Stores balance, currency, and status.
- **Route**: Stores name, origin, destination, JSON stops, and polyline.
- **Bus**: Stores plate_number and total_seats.
- **Trip**: Relates to Route and Bus. Stores departure_time, arrival_time, price, and status.
- **Booking**: Links User and Trip. Stores seat_number, status (LOCKED, PAID, CANCELLED, USED), and qr_code_data. Unique on `(trip_id, seat_number)`.

### Flutter Navigation Routes
**Passenger App (`passenger_app/lib/main.dart`)**:
- `/` -> Redirects to `/login`
- `/login` -> `LoginScreen`
- `/otp` -> `OtpScreen`
- `/splash` -> `SplashScreen`
- `/home` -> `HomeWrapper`
- `/wallet` -> `WalletDashboardScreen`
- `/wallet/deposit` -> `DepositScreen`
- `/search_results` -> `SearchResultsScreen`
- `/bus_details` -> `BusDetailsScreen`
- `/seat_selection` -> `SeatSelectionScreen`
- `/payment` -> `PaymentScreen`
- `/receipt` -> `TicketReceiptScreen`
- `/profile` -> Placeholder Scaffold

**Conductor App (`conductor_app/lib/main.dart`)**:
- Starts at `LoginScreen` (Direct widget reference, no GoRouter implemented yet).

## Current Feature Status

### WORKING
- Database schema generation via manual SQL scripts (`fix_db.py`).
- OTP request and verification (though OTP is randomly generated locally and SMS is stubbed).
- Wallet creation alongside new passenger registration.
- Search Trips endpoint (backend functionality exists).

### STUBBED
- Password checking (currently uses plain text `password == password_hash`).
- `/sell_ticket` (assumes payment succeeded locally without hitting payment provider).
- Profile Screen in passenger app (UI just shows a text placeholder).

### MISSING
- Admin Dashboard implementation.
- Conductor authentication/routing (app just uses direct navigation).
- Ticket seat locking (race condition exists where two users can lock a seat simultaneously).

### Hardcoded Values
- IPs: `192.168.100.19` (in `ip_info.txt`), `127.0.0.1` (in `api_endpoints.dart`).
- Passwords: OTP is hardcoded as randomly generated, and `auth.py` indicates passwords might just be stored as "1234" in seeds.

## Dependencies

### Backend (`pyproject.toml`)
- `fastapi`, `uvicorn`: API framework.
- `tortoise-orm`, `asyncpg`: Async database ORM and driver.
- `redis`: Redis client for OTP caching.
- `passlib`, `python-jose`: Password hashing (unused) and JWT token generation.
- `aerich`: Migration tool.

### Dart/Flutter (`pubspec.yaml`)
**Passenger App**:
- `sentry_flutter`: Crash reporting (has hardcoded DSN).
- `flutter_riverpod`: State management.
- `go_router`: Navigation.
- `dio`: HTTP client.
- `flutter_secure_storage`: Secure token storage.
- `google_maps_flutter`, `maplibre_gl`: Maps.

**Conductor App**:
- Similar state/navigation/networking packages.
- `mobile_scanner`: For scanning ticket QR codes.

## Infrastructure

- **Docker Compose**: Uses `postgres:15-alpine` (db), `redis:7-alpine` (redis), and `backend` (uvicorn API on port 8000). Volumes exist for Postgres data.
- **Environment Variables**: Requires `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `SECRET_KEY`. The `.env` file exists and has `SECRET_KEY=change_this_secret_key` which is insecure.

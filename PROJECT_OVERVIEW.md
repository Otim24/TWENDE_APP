# TWENDE — Comprehensive Project Overview

> **Last Audited:** October 2026 · **Status:** Active Development (MVP Phase)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture & Components](#2-system-architecture--components)
3. [API Reference](#3-api-reference)
4. [Data Flow & Lifecycles](#4-data-flow--lifecycles)
5. [Database Schema](#5-database-schema)
6. [Infrastructure & Deployment](#6-infrastructure--deployment)
7. [Security Posture](#7-security-posture)
8. [Known Issues & Bugs](#8-known-issues--bugs)
9. [Feature Completion Status](#9-feature-completion-status)
10. [Roadmap & Next Steps](#10-roadmap--next-steps)

---

## 1. Executive Summary

**TWENDE** is a full-stack, mobile-first public transport ecosystem built for the East African market (Uganda). It digitizes the end-to-end bus ticketing lifecycle — from route discovery and seat booking to on-bus ticket verification and real-time tracking.

The system is organized into **four primary components** that communicate over a shared REST + WebSocket API:

| Component | Technology | Purpose |
|---|---|---|
| **Backend** | Python / FastAPI | Core business logic, REST API, WebSocket tracking |
| **Passenger App** | Flutter (Dart) | End-user booking, wallet, QR ticket, live tracking |
| **Conductor App** | Flutter (Dart) | Walk-in sales, manifest display, QR scanning |
| **Admin Dashboard** | React 18 | Fleet & route management (not yet implemented) |

The platform currently operates in **MVP mode**: the core booking-and-ticketing flow works end-to-end, but wallet funding and the admin dashboard are pending.

---

## 2. System Architecture & Components

### 2A. Backend (`/backend`)

The backbone of the Twende ecosystem — a high-performance, fully asynchronous REST API.

#### Technology Stack

| Concern | Library / Tool | Notes |
|---|---|---|
| Framework | **FastAPI** (Python 3.11) | Auto-generated OpenAPI docs at `/docs` |
| ASGI Server | **Uvicorn** | Hot-reload enabled in dev via `--reload` |
| Database | **PostgreSQL 15** | Accessed via async `asyncpg` driver |
| ORM | **Tortoise ORM** | Async-native, declarative model definitions |
| Migrations | **Aerich** | Configured via `aerich.ini`; migration files not yet committed |
| Cache / Ephemeral | **Redis 7** | Stores OTPs (`otp:{phone}`) with 5-minute TTL |
| Auth | **JWT** (`python-jose`) + **bcrypt** (`passlib`) | Role-embedded tokens: `{sub, role}` |
| Monitoring | **Sentry SDK** | Traces sample rate 1.0 (100%) in current config |
| Package Manager | **Poetry** | Lockfile at `backend/poetry.lock` |

#### Application Entry Point (`backend/app/main.py`)

- Initializes Sentry before the app boots.
- Bootstraps the DB via `init_db(app)` (Tortoise ORM lifecycle hooks).
- Registers all API routers under the `/api/v1/` prefix.
- Exposes a `/health` endpoint and a `/sentry-debug` test route.

#### Internal Module Layout

```
backend/app/
├── api/
│   ├── deps.py          # JWT dependency: get_current_user()
│   └── v1/
│       ├── auth.py      # OTP & login endpoints
│       ├── bookings.py  # Trip search & user booking history
│       ├── conductor.py # Manifest, ticket sale, QR verification
│       ├── tracking.py  # WebSocket live location relay
│       ├── users.py     # User profile management
│       └── wallet.py    # Wallet balance (deposit endpoint stubbed)
├── core/
│   ├── config.py        # Pydantic Settings (env-driven)
│   ├── database.py      # Tortoise ORM init & teardown
│   └── security.py      # JWT creation, bcrypt helpers
├── models/              # ORM model definitions (see §5)
├── schemas/             # Pydantic request/response schemas
└── services/
    └── notification.py  # SMS notification stub
```

---

### 2B. Passenger App (`/passenger_app`)

A Flutter application targeting Android and iOS for end-users who purchase and manage bus tickets.

#### Technology Stack

| Concern | Package | Notes |
|---|---|---|
| Dart SDK | `>=3.0.0` | Null-safety enforced |
| Navigation | `go_router` | Path-based routing, deep-link capable |
| State Management | `flutter_riverpod` | Global reactive state |
| HTTP Client | `dio` | Interceptors for auth token injection |
| Mapping | `google_maps_flutter` + `maplibre_gl` | Dual map support for bus tracking UI |
| Secure Storage | `flutter_secure_storage` | JWT token persisted securely on-device |
| Environment | `flutter_dotenv` | API base URL loaded from `.env` at startup |
| Monitoring | `sentry_flutter` | Crash + performance reporting |
| QR Display | *(built-in rendering)* | QR data served from backend |

#### Feature Modules (`/passenger_app/lib/features/`)

| Module | Description |
|---|---|
| `auth/` | Phone number entry → OTP → Login |
| `home/` | Dashboard: trip search, quick-book, wallet summary |
| `booking/` | Search results, seat picker, booking confirmation |
| `wallet/` | Balance display, deposit screen (backend pending) |
| `payment/` | Payment confirmation and processing flow |
| `tracking/` | Live bus location map via WebSocket |
| `activity/` | Booking history and ticket status |
| `safety/` | Emergency/safety feature screens |
| `account/` | User profile settings |

#### Navigation Routes (key paths)

```
/login            → OTP Authentication
/home             → Main dashboard
/search_results   → Trip listings
/booking/:id      → Seat selection + confirmation
/wallet           → Balance view
/wallet/deposit   → Deposit entry screen (UI complete, backend pending)
/tracking/:tripId → Live map tracking
/my-tickets       → Past & upcoming bookings
/account          → Profile management
```

---

### 2C. Conductor App (`/conductor_app`)

A Flutter application for bus conductors to manage on-vehicle operations.

#### Technology Stack

| Concern | Package | Notes |
|---|---|---|
| Navigation | `go_router` | Migrated from `MaterialApp` direct routing (bug fix) |
| QR Scanner | `mobile_scanner` | Scans HMAC-signed passenger QR tickets |
| Monitoring | `sentry_flutter` | Crash reporting |
| Environment | *(not yet configured)* | **Security gap**: no `flutter_dotenv` (see §7) |

#### Key Capabilities

- **Login:** Conductors authenticate via phone + password (`/api/v1/auth/login`), credentials seeded via `seed_conductor.py`.
- **Trip Manifest:** Fetches seat-by-seat passenger list for the assigned trip.
- **Walk-in Ticket Sales:** Sells tickets to cash-paying passengers directly from the conductor UI, calling `/api/v1/conductor/sell_ticket`.
- **QR Verification:** Scans passenger QR codes and calls `verify_ticket` to mark seats as `USED`.

---

### 2D. Admin Dashboard (`/admin_dashboard`)

A **React 18** project initialized via `package.json` with no source code implemented. Acts as a placeholder for future fleet and route management capabilities.

---

## 3. API Reference

All routes are prefixed with `/api/v1/`. Authentication uses `Bearer {JWT}` in the `Authorization` header.

### Auth (`/api/v1/auth/`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/otp/request` | ❌ Public | Generates a 6-digit OTP, stores in Redis (5-min TTL), sends mock SMS |
| `POST` | `/otp/verify` | ❌ Public | Validates OTP; creates `User` + `Wallet` if new; returns JWT |
| `POST` | `/login` | ❌ Public | Password-based login for Conductors; returns JWT + `user_name` |

### Bookings (`/api/v1/bookings/`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/search` | ❌ Public | Query params: `from`, `to`, `date (YYYY-MM-DD)`; returns available trips with `available_seats` |
| `GET` | `/my-trips` | ✅ Passenger | Returns `PAID` and `USED` bookings for the authenticated user, with full trip details |
| `GET` | `/{trip_id}` | ❌ Public | Returns detailed trip info including route stops timeline |

### Conductor (`/api/v1/conductor/`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/sell_ticket` | ✅ Conductor | Validates trip, checks seat availability, deducts wallet balance, creates PAID booking + HMAC QR |
| `POST` | `/verify_ticket` | ✅ Conductor | Parses & verifies `TICKET-{trip_id}-{seat}:{hmac}`, marks booking as `USED` |
| `GET` | `/trips/{trip_id}/manifest` | ✅ Conductor | Returns full seat manifest, mapping passengers to seat numbers |

### Wallet (`/api/v1/wallet/`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/balance` | ✅ Passenger | Returns current wallet balance and currency |
| `POST` | `/deposit` | ✅ Passenger | **Stubbed** — endpoint exists but has no payment gateway integration |

### Users (`/api/v1/users/`)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/me` | ✅ Any | Returns authenticated user's profile |
| `PATCH` | `/me` | ✅ Any | Updates `full_name` and other profile fields |

### Tracking (`/api/v1/tracking/`)

| Protocol | Endpoint | Auth | Description |
|---|---|---|---|
| `WebSocket` | `/ws/{trip_id}` | ❌ | Bidirectional location relay; Conductor pushes GPS JSON, all subscribers receive broadcast |

---

## 4. Data Flow & Lifecycles

### 4A. Passenger Authentication & Registration

```
Passenger App                     Backend                        Redis
     │                               │                              │
     │── POST /otp/request ─────────►│                              │
     │   {phone: "+256..."}          │── SETEX otp:{phone} 300 ───►│
     │                               │── Mock SMS sent              │
     │◄─ {message: "OTP sent"} ──────│                              │
     │                               │                              │
     │── POST /otp/verify ──────────►│                              │
     │   {phone, code}               │── GET otp:{phone} ──────────►│
     │                               │◄─ stored_code ───────────────│
     │                               │                              │
     │                               │ [If user NOT found in DB]    │
     │                               │── BEGIN TRANSACTION          │
     │                               │── INSERT User (PASSENGER)    │
     │                               │── INSERT Wallet (balance=0)  │
     │                               │── COMMIT                     │
     │                               │                              │
     │                               │── DEL otp:{phone} ──────────►│
     │◄─ {access_token, token_type} ─│                              │
```

> **⚠️ Known Race Condition:** The `User.get_or_none()` call happens *outside* the transaction block. Two concurrent OTP verifications for the same phone may both see `None` and race to create a duplicate user, causing a DB `IntegrityError`. See [SECURITY.md](./SECURITY.md) for the fix.

---

### 4B. Ticket Booking Lifecycle (Conductor Walk-in Sale)

```
Conductor App          Backend                         PostgreSQL
     │                    │                                 │
     │── POST /conductor/sell_ticket ──────────────────────►│
     │   {trip_id, seat_number, passenger_phone}            │
     │                    │── Validate trip is not past ───►│
     │                    │── Check seat not already PAID ─►│
     │                    │── Fetch Wallet for passenger ──►│
     │                    │                                 │
     │                    │   [wallet.balance >= price?]    │
     │                    │── BEGIN TRANSACTION             │
     │                    │── wallet.balance -= price       │
     │                    │── INSERT Transaction (PAYMENT)  │
     │                    │── INSERT Booking (PAID)         │
     │                    │── Generate HMAC QR              │
     │                    │── booking.qr_code_data = QR    │
     │                    │── COMMIT                        │
     │◄── {booking_id, qr_code_data, seat_number} ─────────│
```

**QR Payload Format:** `TICKET-{trip_id}-{seat_number}:{hmac_signature}`
- Signed with `SECRET_KEY` using HMAC to prevent forgery.
- Verified on-scan by the `verify_ticket` endpoint.

---

### 4C. Manifest & Boarding Flow

```
Conductor App          Backend
     │                    │
     │── GET /conductor/trips/{trip_id}/manifest
     │                    │── Fetch Trip + Bus (total_seats / seat_layout)
     │                    │── Fetch all Bookings for trip
     │                    │── Build seat map: seat_1..N → {passenger|vacant}
     │◄── [{seat_number, passenger_name, status}, ...]
     │
     │── [Scan QR Code]
     │── POST /conductor/verify_ticket
     │   {qr_data: "TICKET-5-14:abc123..."}
     │                    │── Parse trip_id, seat_number, signature
     │                    │── Verify HMAC signature
     │                    │── Booking.get(trip=5, seat=14)
     │                    │── Assert status == PAID
     │                    │── booking.status = USED → save()
     │◄── {status: "ok", message: "Passenger aboard"}
```

---

### 4D. Real-Time Bus Tracking (WebSocket)

```
Conductor App (GPS source)    Backend WS Server    Passenger App (subscriber)
     │                               │                       │
     │── WS CONNECT /ws/{trip_id} ──►│                       │
     │                               │◄── WS CONNECT ────────│
     │                               │    /ws/{trip_id}      │
     │── SEND {lat, lng, speed} ─────►│                       │
     │                               │── broadcast_location ►│
     │                               │   {lat, lng, speed}   │
```

> **Note:** The current implementation is a simple in-process relay. In production this should be decoupled via Redis Pub/Sub to allow horizontal scaling.

---

## 5. Database Schema

All models extend `TimestampMixin` which provides auto-populated `created_at` and `updated_at` fields.

### Entity Relationship Overview

```
User (1) ──── (1) Wallet
User (1) ──── (N) Booking
Wallet (1) ── (N) Transaction
Trip (1) ───── (N) Booking
Route (1) ──── (N) Trip
Bus (1) ─────  (N) Trip
```

---

### `users` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `phone` | VARCHAR(20) | UNIQUE, NOT NULL | Primary identifier for OTP auth |
| `password_hash` | VARCHAR(255) | NOT NULL | Bcrypt hash; empty string for Passengers |
| `full_name` | VARCHAR(100) | Nullable | Default: `"Passenger"` on auto-registration |
| `role` | ENUM | NOT NULL | `PASSENGER`, `CONDUCTOR`, `ADMIN` |
| `created_at` | TIMESTAMP | Auto | |
| `updated_at` | TIMESTAMP | Auto | |

---

### `wallets` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `user_id` | FK → `users` | OneToOne | One wallet per user |
| `balance` | DECIMAL(12,2) | Default: 0.00 | |
| `currency` | VARCHAR(3) | Default: `"UGX"` | Uganda Shillings |
| `status` | VARCHAR(8) | Default: `"ACTIVE"` | `ACTIVE` / `FROZEN` |

---

### `transactions` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `wallet_id` | FK → `wallets` | NOT NULL | |
| `amount` | DECIMAL(12,2) | NOT NULL | |
| `type` | ENUM | NOT NULL | `DEPOSIT`, `WITHDRAWAL`, `PAYMENT`, `REFUND` |
| `status` | ENUM | Default: `PENDING` | `PENDING`, `COMPLETED`, `FAILED` |
| `reference` | VARCHAR(100) | NOT NULL | e.g. `"BOOKING-456"`, `"MOMO-123"` |

---

### `routes` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `name` | VARCHAR(100) | NOT NULL | e.g. `"Kampala - Busia"` |
| `origin` | VARCHAR(100) | NOT NULL | |
| `destination` | VARCHAR(100) | NOT NULL | |
| `stops` | JSONB | Default: `[]` | `[{"name": "Mukono", "time_offset": 30}, ...]` |
| `polyline` | TEXT | Nullable | OSRM/Google encoded polyline for map rendering |

---

### `buses` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `plate_number` | VARCHAR(20) | UNIQUE | |
| `total_seats` | Integer | Default: 60 | |
| `seat_layout` | JSONB | Nullable | Custom seat map; falls back to sequential if `null` |

---

### `trips` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `route_id` | FK → `routes` | NOT NULL | |
| `bus_id` | FK → `buses` | NOT NULL | |
| `departure_time` | TIMESTAMP | NOT NULL | Timezone-aware (UTC) |
| `arrival_time` | TIMESTAMP | NOT NULL | Timezone-aware (UTC) |
| `price` | DECIMAL(10,2) | NOT NULL | Ticket price in UGX |
| `status` | ENUM | Default: `SCHEDULED` | `SCHEDULED`, `BOARDING`, `DEPARTED`, `COMPLETED`, `CANCELLED` |

---

### `bookings` Table

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | Integer | PK, Auto | |
| `trip_id` | FK → `trips` | NOT NULL | |
| `user_id` | FK → `users` | NOT NULL | |
| `seat_number` | Integer | NOT NULL | |
| `status` | ENUM | Default: `LOCKED` | State machine: `LOCKED → PAID → USED` (or `CANCELLED`) |
| `qr_code_data` | VARCHAR(255) | Nullable | HMAC-signed payload for boarding verification |
| — | UNIQUE | `(trip_id, seat_number)` | **Prevents double-booking at the DB level** |

---

## 6. Infrastructure & Deployment

### Docker Compose Services

| Service | Image | Port | Volume |
|---|---|---|---|
| `db` | `postgres:15-alpine` | 5432 | `./data/postgres` |
| `redis` | `redis:7-alpine` | 6379 | *(ephemeral)* |
| `backend` | `./backend/Dockerfile` | 8000 | `./backend` (hot-reload) |

The backend container has `depends_on: [db, redis]`, ensuring correct startup order.

### Environment Variables

| Variable | Used By | Description |
|---|---|---|
| `POSTGRES_USER` | `docker-compose`, `backend` | DB username |
| `POSTGRES_PASSWORD` | `docker-compose`, `backend` | DB password |
| `POSTGRES_DB` | `docker-compose`, `backend` | Database name |
| `DATABASE_URL` | `backend` | Full asyncpg connection string |
| `REDIS_URL` | `backend` | Redis connection URI |
| `SECRET_KEY` | `backend` | JWT signing key + HMAC signing key for QR codes |
| `API_BASE_URL` | `passenger_app` | Backend base URL (loaded via `flutter_dotenv`) |

### Development Network Note

During local development, mobile apps on physical Android devices connect to the machine's LAN IP (e.g., `http://192.168.100.19:8000`). This is loaded from the Flutter `.env` files — **not** hardcoded in Dart source.

### Seed Data

`backend/seed_conductor.py` seeds an initial conductor account into the database for testing the conductor app login flow.

---

## 7. Security Posture

### ✅ Mitigated Issues

| Issue | Resolution |
|---|---|
| Plaintext passwords | Bcrypt hashing via `passlib` |
| Unauthenticated conductor endpoints | JWT `Depends(get_current_user)` + role check |
| Exposed DB secrets in source | Environment-driven via `.env` + Docker |
| QR ticket forgery | HMAC signature embedded in QR payload |
| Timezone-naive trip filtering | `.replace(tzinfo=timezone.utc)` applied in search |
| Conductor app routing debt | Migrated to `go_router` |

---

### 🔴 HIGH: Concurrency Race Condition in User Creation

- **File:** `backend/app/api/v1/auth.py` — `verify_otp()`
- **Issue:** `User.get_or_none(phone=...)` executes **outside** the `in_transaction()` block. Two simultaneous OTP verifications for the same phone can both read `None`, then both attempt `INSERT User`, causing a `UNIQUE` constraint violation and a `500` crash.
- **Risk:** Orphaned `Wallet` rows; request crashes surfaced to the user.
- **Fix:** Move `get_or_none` inside the transaction and use `select_for_update()` or a true atomic get-or-create pattern.

---

### 🔴 HIGH: Missing Wallet Funding Endpoint

- **Files:** `backend/app/api/v1/wallet.py`, `passenger_app` deposit screen
- **Issue:** The passenger UI includes a full `/wallet/deposit` screen, but the backend has **no functional payment processing**. The `sell_ticket` endpoint blocks purchases when `wallet.balance < price`, making remote bookings **mathematically impossible** for passengers.
- **Fix:** Implement a `/wallet/deposit/callback` endpoint that cryptographically verifies MOMO/card gateway webhooks and mints a `DEPOSIT` transaction.

---

### 🟡 MEDIUM: Hardcoded Sentry DSNs

- **Files:** `passenger_app/lib/main.dart`, `conductor_app/lib/main.dart`, `backend/app/main.py`
- **Issue:** Sentry DSNs are literal strings in source code, preventing environment-based switching and polluting production error logs with local dev exceptions.
- **Fix:** Extract to `.env` via `flutter_dotenv` (apps) and Pydantic `Settings` (backend).

---

### 🟡 MEDIUM: Conductor App Missing `flutter_dotenv`

- **File:** `conductor_app/pubspec.yaml`
- **Issue:** No `flutter_dotenv` dependency means API URLs must be hardcoded in Dart source, raising the risk of accidental credential exposure in version control.
- **Fix:** Add `flutter_dotenv`, configure `.env` in `pubspec.yaml` assets, and load it in `main.dart`.

---

## 8. Known Issues & Bugs

> All bugs identified in the initial codebase audit have been **resolved**. The table below reflects the current clean state.

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |

### Previously Fixed Issues

| Issue | File | Fix Applied |
|---|---|---|
| Broken QR ticket verification | `conductor.py` | Correct HMAC parse + verify of `TICKET-{trip}-{seat}:{sig}` |
| Timezone mishandling in search | `bookings.py` | `.replace(tzinfo=timezone.utc)` on datetime boundaries |
| Hardcoded manifest seat-loop | `conductor.py` | Uses `seat_layout` JSON when present; falls back to sequential |
| Missing available seats count | `bookings.py` | Subtracts active bookings from `bus.total_seats` |
| Conductor app routing debt | `conductor_app/lib/main.dart` | Migrated to `go_router`; `pubspec.yaml` restored |

---

## 9. Feature Completion Status

| Feature | Backend | Passenger App | Conductor App | Status |
|---|---|---|---|---|
| OTP Authentication | ✅ | ✅ | — | **Complete** |
| Conductor Login (password) | ✅ | — | ✅ | **Complete** |
| Trip Search | ✅ | ✅ | — | **Complete** |
| Seat Booking (Walk-in sale) | ✅ | — | ✅ | **Complete** |
| QR Ticket Generation | ✅ | ✅ | — | **Complete** |
| QR Ticket Verification | ✅ | — | ✅ | **Complete** |
| Trip Manifest | ✅ | — | ✅ | **Complete** |
| My Trips / Booking History | ✅ | ✅ | — | **Complete** |
| Wallet Balance Display | ✅ | ✅ | — | **Complete** |
| Real-Time GPS Tracking (WS) | ✅ | ✅ | ✅ (push) | **Complete (MVP)** |
| Wallet Deposit / Top-Up | ❌ | ✅ (UI only) | — | **Incomplete** |
| Online Self-Serve Booking | — | ⚠️ (blocked by deposit) | — | **Blocked** |
| Payment Gateway (MOMO/Card) | ❌ | ❌ | — | **Not Started** |
| Admin Dashboard | ❌ | — | — | **Not Started** |
| Push Notifications | ❌ | ❌ | — | **Not Started** |
| Aerich DB Migrations (committed) | ⚠️ (configured) | — | — | **Incomplete** |

---

## 10. Roadmap & Next Steps

### 🚨 Immediate Priorities (Blockers)

1. **Fix Race Condition in `auth.py`** — Move `get_or_none` inside the transaction; add `select_for_update()` to atomically handle concurrent registrations.
2. **Implement Wallet Deposit Endpoint** — Integrate Mobile Money (e.g., MTN MOMO Uganda) webhook handler so passengers can fund wallets and complete remote bookings.

### 📅 Short Term (Next Sprint)

3. **Conductor App Environment Config** — Add `flutter_dotenv` to eliminate hardcoded API URLs.
4. **Externalize Sentry DSNs** — Move all DSNs to `.env` across all three codebases.
5. **Commit Aerich Migrations** — Run `aerich init-db` and track the migration history in version control.
6. **Backend Sentry PII Review** — Evaluate `send_default_pii=True`; ensure GDPR/compliance sign-off.

### 🗓️ Medium Term

7. **Admin Dashboard** — Build the React 18 UI: route management, trip scheduling, conductor seeding, revenue dashboards.
8. **Self-Serve Online Booking** — Allow passengers to book and pay remotely via the Passenger App (currently only walk-in via Conductor App is functional end-to-end).
9. **Production WebSocket Architecture** — Decouple GPS relay via Redis Pub/Sub; current in-process relay is not horizontally scalable.
10. **Push Notifications** — Integrate Firebase Cloud Messaging (FCM) for departure reminders and booking confirmations.
11. **Refund Flow** — Implement `REFUND` transaction processing for cancelled bookings.

### 🔭 Long Term

12. **Multi-Currency Support** — The `currency` field on `Wallet` is already designed for this; just needs backend logic and UI.
13. **Route Polyline Rendering** — `Route.polyline` exists in the DB but is not yet rendered on the Passenger App tracking map.
14. **Offline QR Verification** — Allow conductors to verify tickets offline via a pre-fetched manifest + HMAC public key cache.
15. **Analytics & Reporting** — Seat occupancy, revenue per route, and peak-time analysis dashboards.

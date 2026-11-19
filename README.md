# Twende — Public Transport Booking, Ticketing & Live Tracking Platform

**Twende** is a full-stack public transport platform built for bus operators and passengers in Uganda and East Africa. It connects a Dockerized **FastAPI + PostgreSQL + Redis** backend with two native **Flutter** mobile apps (**Passenger** and **Conductor**) to handle OTP/JWT authentication, route & trip search, interactive seat selection, UGX wallet payments, HMAC-signed QR boarding passes, walk-in cash sales, and real-time WebSocket GPS tracking.

---

## Table of Contents

1. [Repository Architecture](#1-repository-architecture)
2. [Tech Stack](#2-tech-stack)
3. [Core Features & End-to-End Flows](#3-core-features--end-to-end-flows)
4. [Quick Start (Docker Backend + Seed Data)](#4-quick-start-docker-backend--seed-data)
5. [Mobile Apps Setup & Physical Device Testing](#5-mobile-apps-setup--physical-device-testing)
6. [API Reference (`/api/v1`)](#6-api-reference-apiv1)
7. [Testing & Verification](#7-testing--verification)
8. [Security & Engineering Guarantees](#8-security--engineering-guarantees)
9. [Project Documentation](#9-project-documentation)

---

## 1. Repository Architecture

```text
Twende_App/
├── backend/                 # Async FastAPI REST + WebSocket API, Tortoise ORM models, seed & tests
│   ├── app/
│   │   ├── api/             # Auth dependencies & v1 routers (auth, users, wallet, bookings, conductor, tracking)
│   │   ├── core/            # Pydantic Settings, Tortoise DB init, JWT/bcrypt/HMAC security helpers
│   │   ├── models/          # User, Wallet, Transaction, Bus, Route, Trip, Booking models
│   │   ├── schemas/         # Request/response schemas
│   │   └── services/        # SMS notification service stub (OTP logs / Redis-backed delivery)
│   ├── tests/               # Backend transactional, auth, booking & security integration tests
│   ├── Dockerfile
│   ├── pyproject.toml       # Poetry dependency manifest
│   └── seed_conductor.py    # Idempotent schema reconciliation + conductor, bus, route & trip seeder
├── passenger_app/           # Native Flutter mobile app for passengers (Android/iOS)
│   ├── lib/
│   │   ├── config/          # Dark AppTheme configuration
│   │   ├── core/            # AppTokens (Decimal-safe UGX formatters), ApiClient (Dio + JWT), StorageService
│   │   └── features/        # splash, login/OTP, home, search, bus details, seat map, wallet, payment, QR receipt, activity, tracking, account
│   └── test/                # Flutter unit & widget tests
├── conductor_app/           # Native Flutter mobile app for bus conductors (Android/iOS)
│   ├── lib/
│   │   ├── core/            # AppTokens, AuthSession + Dio client, GpsBroadcastService (WebSocket)
│   │   └── features/        # login, live trip manifest, passenger list, seat grid, walk-in ticket sales, QR scanner
│   └── test/                # Flutter unit & widget tests
├── admin_dashboard/         # React 18 TypeScript web placeholder (scaffolded directories)
├── docker-compose.yml       # Orchestrates PostgreSQL 15, Redis 7, and FastAPI backend
├── AGENTS.md                # Developer & AI agent workspace conventions
├── PROJECT_OVERVIEW.md      # Detailed architecture, schema & sequence diagrams
├── SECURITY.md              # Security audit remediation status
└── BUGS.md                  # Bug audit & fix history
```

---

## 2. Tech Stack

| Component | Technologies & Key Packages | Package Manager |
|---|---|---|
| **Backend API** (`backend/`) | Python 3.11, FastAPI `^0.109.0`, Uvicorn, Tortoise ORM `^0.20.0`, `asyncpg`, Aerich, Pydantic Settings, `passlib[bcrypt]`, `python-jose`, `redis ^5.0.1` | Poetry (`pyproject.toml`, `poetry.lock`) |
| **Database & Cache** | PostgreSQL `15-alpine` (`:5432`), Redis `7-alpine` (`:6379`) | Docker Compose |
| **Passenger App** (`passenger_app/`) | Flutter / Dart `>=3.0.0`, Riverpod, `go_router`, `dio`, `flutter_dotenv`, `flutter_secure_storage`, `qr_flutter`, `maplibre_gl`, `web_socket_channel`, `pinput`, `gal`, `share_plus` | Flutter Pub (`pubspec.yaml`, `pubspec.lock`) |
| **Conductor App** (`conductor_app/`) | Flutter / Dart `^3.0.0`, Riverpod, `go_router`, `dio`, `flutter_dotenv`, `mobile_scanner`, `qr_flutter`, `web_socket_channel`, `share_plus`, `gal` | Flutter Pub (`pubspec.yaml`, `pubspec.lock`) |
| **Admin Dashboard** (`admin_dashboard/`) | React `^18.2.0` (scaffolded placeholder) | npm / yarn (`package.json`) |

---

## 3. Core Features & End-to-End Flows

### Passenger Flow (`passenger_app`)
- **Passwordless OTP Onboarding:** Enter Ugandan phone number (`+256...`), verify 6-digit Redis-backed OTP (with 60s resend cooldown and 5-attempt lockout), and set display name (`PATCH /api/v1/users/me`).
- **Live Trip Search & Seat Map:** Search scheduled trips by origin, destination, and `YYYY-MM-DD` date (`GET /api/v1/bookings/search`), inspect route timeline stops (`GET /api/v1/bookings/{trip_id}`), and select multiple open seats from live bus capacity.
- **Twende Wallet & Checkout:** Top up wallet balance (`POST /api/v1/wallet/deposit`) and complete slide-to-pay multi-seat bookings (`POST /api/v1/bookings`) backed by atomic `Decimal` ledger debits.
- **HMAC E-Tickets & Live Map Tracking:** View, save, or share scannable per-seat HMAC QR boarding passes (`TICKET-{trip_id}-{seat}:{hmac_sha256}`), browse upcoming/past trips under Activity, and follow live conductor GPS telemetry on MapLibre (`WS /api/v1/tracking/ws/{trip_id}`).

### Conductor Flow (`conductor_app`)
- **Authenticated Shift Login:** Sign in with phone + bcrypt-verified password (`POST /api/v1/auth/login`, role `CONDUCTOR`).
- **Live Trip & Seat Manifest:** Switch between active trips (`GET /api/v1/conductor/trips`), filter passengers (`BOOKED` vs `OCCUPIED`), and inspect the live bus seat grid (`GET /api/v1/conductor/trips/{trip_id}/manifest`).
- **QR Ticket Verification & Manual Boarding:** Scan passenger QR codes with `mobile_scanner` or tap manifest rows to board passengers atomically (`POST /api/v1/conductor/verify_ticket`), preventing replay scans and wrong-trip tickets.
- **Walk-In Cash Ticket Sales & GPS Telemetry:** Sell available seats to walk-in passengers (`POST /api/v1/conductor/sell_ticket`), generate/share an instant HMAC QR receipt, and broadcast live GPS updates to passengers over authenticated WebSocket (`?token=<jwt>`).

---

## 4. Quick Start (Docker Backend + Seed Data)

### 1. Configure Environment Variables
Copy the example templates and set strong local credentials (never commit `.env` files):

```bash
cp .env.example .env
cp backend/app/.env.example backend/.env
```

Root `.env` variables used by `docker-compose.yml`:
- `POSTGRES_USER` (e.g. `postgres`)
- `POSTGRES_PASSWORD`
- `POSTGRES_DB` (e.g. `twende`)
- `SECRET_KEY` (used for JWT signing and QR HMAC signatures)

### 2. Start PostgreSQL, Redis, and FastAPI

```bash
docker compose up -d --build
docker compose ps
```

Check API health:
```bash
curl http://localhost:8000/health
```

Interactive OpenAPI docs are available at `http://localhost:8000/docs`.

### 3. Seed Initial Conductor, Bus, Route & Trip Data

```bash
docker compose exec -T backend python seed_conductor.py
```

Default seeded test entities:
- **Conductor account:** phone `0700000000`, password `1234` (bcrypt-hashed, role `CONDUCTOR`)
- **Bus:** `UBA 123X` (60 seats)
- **Route:** `Kampala - Gulu` (4 stops)
- **Trip:** Active future UTC `SCHEDULED` trip priced at `30000.00 UGX`

### Local OTP Retrieval (Development SMS Stub)
In local development, `backend/app/services/notification.py` logs OTP codes instead of calling a paid SMS gateway, while storing them in Redis (`otp:+256...`, 5-minute TTL). To read an active passenger OTP during local phone testing:

```bash
docker compose exec -T redis redis-cli GET "otp:+256784811929"
```

---

## 5. Mobile Apps Setup & Physical Device Testing

Because physical phones resolve `127.0.0.1` to the phone itself, configure each mobile app's `.env` with your host machine's LAN IP (detected via `ip -4 addr`):

```bash
cp passenger_app/.env.example passenger_app/.env
cp conductor_app/.env.example conductor_app/.env
```

Edit both `.env` files:
```env
BASE_URL=http://<YOUR_LAN_IP>:8000/api/v1
WS_URL=ws://<YOUR_LAN_IP>:8000/api/v1/tracking
```

### Run & Install `passenger_app`
```bash
cd passenger_app
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Run & Install `conductor_app`
```bash
cd conductor_app
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 6. API Reference (`/api/v1`)

| Domain | Method / Protocol | Endpoint | Auth | Purpose |
|---|---|---|---|---|
| **Health** | `GET` | `/health` | Public | Service health check |
| **Auth** | `POST` | `/api/v1/auth/otp/request` | Public | Generate 6-digit OTP (60s cooldown, 5m TTL) |
| **Auth** | `POST` | `/api/v1/auth/otp/verify` | Public | Verify OTP (5-attempt lockout), return `PASSENGER` JWT |
| **Auth** | `POST` | `/api/v1/auth/login` | Public | Phone + password login (`CONDUCTOR` / `ADMIN`) |
| **Users** | `GET` | `/api/v1/users/me` | Bearer JWT | Get current authenticated profile |
| **Users** | `PATCH` | `/api/v1/users/me` | Bearer JWT | Update `full_name` |
| **Wallet** | `GET` | `/api/v1/wallet/balance` | Bearer JWT | Get UGX wallet balance & status |
| **Wallet** | `POST` | `/api/v1/wallet/deposit` | Bearer JWT | Atomic wallet top-up with `Decimal` & row lock |
| **Bookings** | `GET` | `/api/v1/bookings/search` | Public | Search active trips (`from`, `to`, `date`) |
| **Bookings** | `GET` | `/api/v1/bookings/{trip_id}` | Public | Trip details, stops timeline, `seat_layout`, `booked_seats` |
| **Bookings** | `GET` | `/api/v1/bookings/my-trips` | Bearer JWT | Authenticated passenger's active/used tickets + QR data |
| **Bookings** | `POST` | `/api/v1/bookings` | Bearer JWT | Atomic multi-seat checkout, wallet debit & HMAC QR issue |
| **Conductor** | `GET` | `/api/v1/conductor/trips` | Conductor JWT | Active trips with `bus_plate`, `price`, & occupancy counts |
| **Conductor** | `GET` | `/api/v1/conductor/trips/{trip_id}/manifest` | Conductor JWT | Full seat-by-seat manifest |
| **Conductor** | `POST` | `/api/v1/conductor/sell_ticket` | Conductor JWT | Atomic walk-in seat sale + HMAC QR generation |
| **Conductor** | `POST` | `/api/v1/conductor/verify_ticket` | Conductor JWT | Verify HMAC QR or manual booking ID & mark `USED` |
| **Tracking** | `WS` | `/api/v1/tracking/ws/{trip_id}` | Public listen / Conductor JWT broadcast | Live GPS coordinate broadcast & subscription |

---

## 7. Testing & Verification

### Backend Integration Tests
Runs full auth, OTP security, wallet concurrency/precision, multi-seat booking, conductor manifest/QR verification, and WebSocket RBAC tests against PostgreSQL & Redis:

```bash
docker compose exec -T backend python -m unittest tests/test_remediation.py -v
```

### Passenger App Static Analysis & Tests
```bash
cd passenger_app
flutter analyze
flutter test
```

### Conductor App Static Analysis & Tests
```bash
cd conductor_app
flutter analyze
flutter test
```

---

## 8. Security & Engineering Guarantees

- **Exact Currency Math:** All backend UGX fares, wallet balances, and transaction amounts use `Decimal` (`max_digits=12, decimal_places=2`), and both Flutter apps parse backend decimal strings (`"30000.00"`) cleanly via `AppTokens.parseUgx` without float drift or decimal-merging bugs.
- **Transactional Concurrency Control:** All seat reservations, walk-in sales, wallet deposits/debits, and boarding verifications run inside `async with in_transaction():` with row-level `.select_for_update()` locks plus database-level `unique_together = (("trip", "seat_number"),)` constraints.
- **QR Ticket Integrity:** Tickets are signed as `TICKET-{trip_id}-{seat}:{hmac_sha256}` using `SECRET_KEY` and verified in constant time via `hmac.compare_digest`.
- **Secret Isolation:** `.env` files and `sentry.properties` are gitignored, backend `Settings` marks `DATABASE_URL`, `SECRET_KEY`, and `SENTRY_DSN` with `Field(repr=False, exclude=True)`, and Flutter Dio interceptors redact tokens and QR payloads from logs.

---

## 9. Project Documentation

- [`AGENTS.md`](./AGENTS.md) — Service boundaries, LAN networking, and engineering rules
- [`PROJECT_OVERVIEW.md`](./PROJECT_OVERVIEW.md) — Detailed system diagrams and Tortoise ORM schema
- [`SECURITY.md`](./SECURITY.md) — Security audit findings & remediations
- [`BUGS.md`](./BUGS.md) — Audit bug tracker & fixes

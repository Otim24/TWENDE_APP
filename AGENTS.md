# Agent Instructions

## Service Boundaries & Tech Stack

| Directory | Role | Stack & SDK Versions | Package Manager |
|-----------|------|----------------------|-----------------|
| `backend/` | Async REST + WebSocket API (`:8000`), PostgreSQL (`:5432`), Redis (`:6379`) | Python `^3.11`, FastAPI `^0.109.0`, Uvicorn `^0.27.0`, Tortoise ORM `^0.20.0`, `asyncpg ^0.29.0`, Aerich `^0.7.2`, Redis `^5.0.1`, PostgreSQL `15-alpine`, Redis `7-alpine` | **Poetry** (`poetry.lock`) |
| `passenger_app/` | **Native Mobile App** (Android/iOS — NOT web/PWA) for booking, wallet, QR tickets, live GPS tracking | Flutter / Dart SDK `>=3.0.0 <4.0.0`, `flutter_riverpod ^2.4.9`, `go_router ^12.1.0`, `dio ^5.4.0`, `flutter_dotenv ^6.0.1`, `flutter_secure_storage ^9.0.0`, `maplibre_gl ^0.25.0`, `google_maps_flutter ^2.14.0` | **Flutter Pub** (`pubspec.lock`) |
| `conductor_app/` | **Native Mobile App** (Android/iOS — NOT web/PWA) for manifest, walk-in sales, QR scanning | Flutter / Dart SDK `^3.0.0`, `go_router ^17.0.1`, `dio ^5.9.0`, `mobile_scanner ^7.1.4`, `flutter_dotenv ^6.0.1`, `flutter_riverpod ^3.2.0`, `qr_flutter ^4.1.0`, `gal ^2.3.2`, `share_plus ^12.0.1`, `sentry_flutter ^9.21.0` | **Flutter Pub** (`pubspec.lock`) |
| `admin_dashboard/` | Web Admin Dashboard (unimplemented placeholder; empty `src/*.tsx` stubs) | React `^18.2.0`, `react-dom ^18.2.0`, TypeScript | **npm / yarn** (`package.json`) |

## Commands (Fedora Linux & Docker)

| Task | Command |
|------|---------|
| Start stack (rebuild) | `docker compose up -d --build` |
| Service status & logs | `docker compose ps` / `docker compose logs --tail=30 backend` |
| Run backend integration tests | `docker compose exec -T backend python -m unittest tests/test_remediation.py -v` |
| Seed conductor & trip | `docker compose exec -T backend python seed_conductor.py` |
| Passenger app analyze | `cd passenger_app && ~/flutter/bin/flutter analyze` |
| Conductor app analyze & test | `cd conductor_app && ~/flutter/bin/flutter analyze && ~/flutter/bin/flutter test` |
| Build & install Conductor APK | `cd conductor_app && ~/flutter/bin/flutter build apk --debug && ~/Android/Sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk` |

## Local Network / LAN IP Rules (Native Mobile → Docker Backend)
- Native mobile apps run on physical Android/iOS devices or emulators; `127.0.0.1` / `localhost` resolves to the handset itself, never the Fedora host.
- Bind `backend` to `0.0.0.0:8000` in `docker-compose.yml` and detect the active Fedora host LAN IP via `ip -4 addr` (saved in `ip_info.txt`).
- `passenger_app/.env` and `conductor_app/.env` define `BASE_URL=http://<LAN_IP>:8000/api/v1` and `WS_URL=ws://<LAN_IP>:8000/api/v1/tracking` (current Fedora LAN IP: `192.168.1.71`).
- Both mobile apps must resolve backend endpoints exclusively through their centralized `flutter_dotenv` config modules (`passenger_app/lib/core/api/api_endpoints.dart` and `conductor_app/lib/core/api/api_endpoints.dart`); never hardcode LAN IPs in screen/widget files.
- Active Backend Endpoints (`/api/v1`):
  - Auth: `POST /auth/otp/request`, `POST /auth/otp/verify`, `POST /auth/login`
  - Users: `GET /users/me`, `PATCH /users/me`
  - Wallet: `GET /wallet/balance`, `POST /wallet/deposit`
  - Bookings: `GET /bookings/search`, `GET /bookings/my-trips`, `GET /bookings/{trip_id}`, `POST /bookings`
  - Conductor: `GET /conductor/trips`, `GET /conductor/trips/{trip_id}/manifest`, `POST /conductor/sell_ticket`, `POST /conductor/verify_ticket`
  - Tracking: `WS /tracking/{trip_id}` & `WS /tracking/ws/{trip_id}` (broadcast requires `CONDUCTOR` JWT via `?token=<jwt>` or `Authorization` header)

## Key Engineering Rules
- **Math & Fare Precision**: Always use `Decimal` (`DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))` for wallets/transactions, `max_digits=10, decimal_places=2` for trip prices in `UGX`). Never use IEEE 754 `float` for currency, fares, or balances.
- **Concurrency & Locking**: Wrap multi-step state mutations (user/wallet creation, wallet deposits/debits, seat booking, QR/manual ticket verification) inside `async with in_transaction():` with row-level locks (`select_for_update()`) on `Trip`, `Booking`, and `Wallet`.
- **Security**: Never print or commit secret values from `.env`, `backend/.env`, `passenger_app/.env`, or `conductor_app/.env`. Keep `Field(repr=False, exclude=True)` on all secret fields in `backend/app/core/config.py`. Sign and verify QR payloads (`TICKET-{trip_id}-{seat}:{hmac_sha256}`) via `generate_ticket_qr_data` and `hmac.compare_digest`.
- **Native Mobile UI/UX**: `passenger_app` and `conductor_app` are strictly native Flutter mobile apps—never introduce DOM/web idioms or PWA wrappers. Use `SafeArea`, virtualized lists (`ListView.builder`), explicit loading/error states, and `go_router` navigation.

## External References

| Need | File |
|------|------|
| System architecture, schema & API reference | `PROJECT_OVERVIEW.md` |
| Active security vulnerabilities & remediation | `SECURITY.md` |
| Resolved bug audit history | `BUGS.md` |
| Container orchestration & ports | `docker-compose.yml` |
| Environment variable template | `.env.example` |

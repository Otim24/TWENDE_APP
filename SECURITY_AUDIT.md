# SECURITY AUDIT

## Summary Table

| Severity | Count |
|---|---|
| CRITICAL | 3 |
| HIGH | 4 |
| MEDIUM | 2 |

## Authentication & Authorization

### CRITICAL: Broken Access Control (OWASP A01)
- **Location**: `backend/app/api/v1/conductor.py` (lines 16, 60, 113, 174)
- **Vulnerability**: Endpoints like `/verify_ticket`, `/sell_ticket`, `/trips`, and `/trips/{trip_id}/manifest` completely lack the JWT token dependency (`Depends(get_current_user)`). There is also no RBAC checking if the user is genuinely a `CONDUCTOR`.
- **Danger**: Any unauthenticated user over the internet can hit these endpoints to generate free tickets, view passenger manifests, and mark tickets as used.
- **Fix**: Add authentication and role-based access control to these endpoints:
  ```python
  from app.api.deps import get_current_user
  from app.models.user_model import User, UserRole

  @router.post("/verify_ticket", response_model=TicketVerifyResponse)
  async def verify_ticket(request: TicketVerifyRequest, current_user: User = Depends(get_current_user)):
      if current_user.role != UserRole.CONDUCTOR:
          raise HTTPException(status_code=403, detail="Not authorized")
      # ... rest of logic
  ```

### CRITICAL: Cryptographic Failures - Plain Text Passwords (OWASP A02)
- **Location**: `backend/app/api/v1/auth.py` (lines 95-97)
- **Vulnerability**: Passwords are saved and verified directly without hashing (`if user.password_hash != payload.password:`).
- **Danger**: If the database is compromised, all user passwords are exposed instantly.
- **Fix**: Implement `passlib` for bcrypt hashing (already in `security.py`).
  ```python
  from passlib.context import CryptContext
  pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
  
  # For verifying during login
  if not pwd_context.verify(payload.password, user.password_hash):
      raise HTTPException(status_code=400, detail="Invalid credentials")
  ```

### CRITICAL: Security Misconfiguration - Exposed Secrets (OWASP A05)
- **Location**: `.env` and `docker-compose.yml`
- **Vulnerability**: The `.env` file containing `SECRET_KEY=change_this_secret_key` and Postgres database credentials is committed to Git.
- **Danger**: Anyone with access to the repo can decrypt JWT tokens, forge admin sessions, and access the database.
- **Fix**: Add `.env` to `.gitignore`. Generate a secure 32-byte key using `openssl rand -hex 32` and store it securely via CI/CD for production.

## Input Validation

### HIGH: Insecure OTP Generation
- **Location**: `backend/app/api/v1/auth.py` (line 28)
- **Vulnerability**: `random.randint(100000, 999999)` is used for OTP generation. The standard `random` library is not cryptographically secure.
- **Danger**: An attacker could potentially predict the sequence of random numbers and bypass OTP validation.
- **Fix**: Use Python's `secrets` module which is designed for cryptography.
  ```python
  import secrets
  code = str(secrets.randbelow(900000) + 100000)
  ```

## Data Exposure

### MEDIUM: Sensitive Data Exposure in Responses
- **Location**: `backend/app/api/v1/users.py` (line 13)
- **Vulnerability**: Returning internal database structures directly. Although the current `/me` endpoint maps specific fields, `id` and `phone` numbers are exposed.
- **Danger**: Leaks internal Identifiers. 
- **Fix**: Make sure to map schemas thoroughly and avoid sharing more PII than necessary.

## Transport Security

### HIGH: Cleartext Traffic Allowed
- **Location**: Android Manifests (Passenger and Conductor apps)
- **Vulnerability**: `android:usesCleartextTraffic="true"` is enabled. All API calls default to HTTP instead of HTTPS. WebSocket connections might also be unencrypted.
- **Danger**: Man-in-The-Middle (MITM) attackers can intercept JWT tokens, phone numbers, and OTP codes over public Wi-Fi.
- **Fix**: Set `android:usesCleartextTraffic="false"` and ensure the backend uses an HTTPS proxy (like Nginx or Traefik) with a valid SSL/TLS certificate. Update any WS connections to use `wss://`.

## Mobile App Security

### HIGH: Insecure QR Code Ticketing
- **Location**: `backend/app/api/v1/conductor.py` (line 94)
- **Vulnerability**: `qr_code_data=f"TICKET-{trip.id}-{payload.seat_number}"`. The QR code contains easily guessable plain text data.
- **Danger**: A malicious passenger can generate their own QR code by incrementing seat numbers and bypass the payment system entirely.
- **Fix**: Generate an HMAC signature for the QR code payload.
  ```python
  import hmac, hashlib
  payload = f"TICKET-{trip.id}-{payload.seat_number}"
  signature = hmac.new(settings.SECRET_KEY.encode(), payload.encode(), hashlib.sha256).hexdigest()
  qr_code_data = f"{payload}:{signature}"
  ```

## Business Logic Vulnerabilities

### HIGH: Race Condition in Booking
- **Location**: `backend/app/api/v1/conductor.py` (line 68)
- **Vulnerability**: The `sell_ticket` endpoint checks for existing seats with `await Booking.filter(...).exists()`, and then later creates the booking.
- **Danger**: Two concurrent requests for the exact same seat will both pass the `.exists()` check and proceed to create duplicate bookings.
- **Fix**: The Tortoise model has a `unique_together` constraint, but proper error handling must be implemented to catch the `IntegrityError` when duplicates occur.

### MEDIUM: Past Trip Ticketing
- **Location**: `backend/app/api/v1/conductor.py` (line 60)
- **Vulnerability**: A conductor can call `sell_ticket` with a `trip_id` that occurred in the past.
- **Danger**: Can skew financial records and manifest accuracy.
- **Fix**: Check `if trip.departure_time < datetime.now(timezone.utc): raise HTTPException(...)`

## Recommendations

1. **Immediate Actions (Critical)**:
   - Add `.env` to `.gitignore`.
   - Add `Depends(get_current_user)` to all conductor endpoints and add RBAC to ensure the user is a `CONDUCTOR`.
   - Implement `bcrypt` password hashing using the existing `get_password_hash` in `security.py`.
2. **Short Term (High)**:
   - Implement HMAC signing for the QR codes to prevent forgery.
   - Implement rate limiting on the `/otp/request` endpoint to prevent SMS bombing attacks.
   - Force HTTPS on all mobile app traffic and disable cleartext traffic.
3. **Long Term (Medium)**:
   - Add audit logging for financial transactions (deposits, payments, refunds).
   - Setup a proper secrets manager (e.g. AWS Secrets Manager, Hashicorp Vault) instead of committing secrets into git.

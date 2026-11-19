import asyncio
from decimal import Decimal
import json
import secrets
import unittest
import urllib.error
import urllib.request
import redis
import websockets

from app.core.config import settings


BASE_URL = "http://127.0.0.1:8000"
WS_BASE_URL = "ws://127.0.0.1:8000"
sync_redis = redis.from_url(settings.REDIS_URL, decode_responses=True)


def http_request(method: str, path: str, data: dict | None = None, token: str | None = None) -> tuple[int, dict]:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(f"{BASE_URL}{path}", data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            parsed = json.loads(raw)
        except Exception:
            parsed = {"raw": raw}
        return e.code, parsed


class BackendRemediationTests(unittest.TestCase):
    def test_01_secret_serialization_and_sentry_debug_removed(self):
        s_repr = repr(settings)
        self.assertNotIn(settings.SECRET_KEY, s_repr)
        self.assertNotIn(settings.DATABASE_URL, s_repr)
        dumped = settings.model_dump()
        self.assertNotIn("SECRET_KEY", dumped)
        self.assertNotIn("DATABASE_URL", dumped)

        status_code, _ = http_request("GET", "/sentry-debug")
        self.assertEqual(status_code, 404)

    def test_02_conductor_login_and_otp_security(self):
        # 1. Seeded conductor login with "1234" succeeds (200 OK + JWT)
        status_code, body = http_request(
            "POST",
            "/api/v1/auth/login",
            {"phone": "0700000000", "password": "1234"},
        )
        self.assertEqual(status_code, 200, f"Conductor login failed: {body}")
        self.assertIn("access_token", body)

        # 2. Wrong password returns 400 (never 500)
        status_code, _ = http_request(
            "POST",
            "/api/v1/auth/login",
            {"phone": "0700000000", "password": "wrong-password"},
        )
        self.assertEqual(status_code, 400)

        # 3. Conductor phone cannot bypass password via OTP verify (403 Forbidden)
        sync_redis.delete("otp_attempts:0700000000")
        sync_redis.setex("otp:0700000000", 300, "111222")
        status_code, body = http_request(
            "POST",
            "/api/v1/auth/otp/verify",
            {"phone": "0700000000", "code": "111222"},
        )
        self.assertEqual(status_code, 403, f"Expected 403 for conductor OTP verify: {body}")

        # 4. OTP 60s request cooldown + 5-attempt lockout
        test_phone = f"+25679{secrets.randbelow(9000000) + 1000000}"
        status1, _ = http_request("POST", "/api/v1/auth/otp/request", {"phone": test_phone})
        self.assertEqual(status1, 200)
        status2, _ = http_request("POST", "/api/v1/auth/otp/request", {"phone": test_phone})
        self.assertEqual(status2, 429)

        real_code = sync_redis.get(f"otp:{test_phone}")
        for _ in range(5):
            st, _ = http_request("POST", "/api/v1/auth/otp/verify", {"phone": test_phone, "code": "000000"})
            self.assertIn(st, (400, 429))
        st_after, _ = http_request("POST", "/api/v1/auth/otp/verify", {"phone": test_phone, "code": real_code})
        self.assertIn(st_after, (400, 429))

    def test_03_end_to_end_passenger_deposit_booking_and_conductor_verification(self):
        # 1. Passenger OTP request + verify
        passenger_phone = f"+25678{secrets.randbelow(9000000) + 1000000}"
        st_req, body_req = http_request("POST", "/api/v1/auth/otp/request", {"phone": passenger_phone})
        self.assertEqual(st_req, 200, body_req)
        otp_code = sync_redis.get(f"otp:{passenger_phone}")
        self.assertIsNotNone(otp_code)

        st_ver, body_ver = http_request(
            "POST",
            "/api/v1/auth/otp/verify",
            {"phone": passenger_phone, "code": otp_code},
        )
        self.assertEqual(st_ver, 200, body_ver)
        passenger_token = body_ver["access_token"]

        # 2. Check & update user profile (GET & PATCH /api/v1/users/me)
        st_me, body_me = http_request("GET", "/api/v1/users/me", token=passenger_token)
        self.assertEqual(st_me, 200, body_me)
        st_patch, body_patch = http_request(
            "PATCH",
            "/api/v1/users/me",
            {"full_name": "Ada Lovelace"},
            token=passenger_token,
        )
        self.assertEqual(st_patch, 200, body_patch)
        self.assertEqual(body_patch["full_name"], "Ada Lovelace")

        # 3. Deposit into passenger wallet (Decimal precision check)
        st_dep, body_dep = http_request(
            "POST",
            "/api/v1/wallet/deposit",
            {"amount": "100000.50", "reference": "MOMO-TEST-001"},
            token=passenger_token,
        )
        self.assertEqual(st_dep, 200, body_dep)
        self.assertEqual(Decimal(str(body_dep["balance"])), Decimal("100000.50"))

        # 4. Conductor login to find active seeded trip
        st_clog, body_clog = http_request(
            "POST",
            "/api/v1/auth/login",
            {"phone": "0700000000", "password": "1234"},
        )
        self.assertEqual(st_clog, 200, body_clog)
        conductor_token = body_clog["access_token"]

        st_trips, trips = http_request("GET", "/api/v1/conductor/trips", token=conductor_token)
        self.assertEqual(st_trips, 200, trips)
        self.assertTrue(len(trips) > 0, "Expected at least 1 seeded scheduled trip")
        self.assertIn("bus_plate", trips[0])
        self.assertIn("price", trips[0])
        self.assertTrue(bool(trips[0]["bus_plate"]))
        self.assertGreater(Decimal(str(trips[0]["price"])), Decimal("0.00"))
        trip_id = trips[0]["id"]

        # 5. Inspect trip details to find available seats
        st_td, trip_details = http_request("GET", f"/api/v1/bookings/{trip_id}")
        self.assertEqual(st_td, 200, trip_details)
        self.assertIn("booked_seats", trip_details)
        self.assertIn("seat_layout", trip_details)
        taken = set(trip_details["booked_seats"])
        free_seats = [s for s in trip_details["seat_layout"] if s not in taken]
        self.assertGreaterEqual(len(free_seats), 3)
        seat_a, seat_b, seat_c = free_seats[0], free_seats[1], free_seats[2]
        trip_price = Decimal(str(trip_details["price"]))

        # 6. Out-of-bounds seat booking must be rejected with 400
        st_oob, body_oob = http_request(
            "POST",
            "/api/v1/bookings",
            {"trip_id": trip_id, "seat_numbers": [999], "payment_method": "WALLET"},
            token=passenger_token,
        )
        self.assertEqual(st_oob, 400, f"Expected 400 for out-of-bounds seat: {body_oob}")

        # 7. Passenger books 2 seats (seat_a, seat_b) via POST /api/v1/bookings
        st_book, body_book = http_request(
            "POST",
            "/api/v1/bookings",
            {"trip_id": trip_id, "seat_numbers": [seat_a, seat_b], "payment_method": "WALLET"},
            token=passenger_token,
        )
        self.assertEqual(st_book, 200, body_book)
        self.assertEqual(len(body_book["bookings"]), 2)
        expected_total = trip_price * Decimal(2)
        self.assertEqual(Decimal(str(body_book["total_price"])), expected_total)

        # Verify wallet balance after deduction
        st_bal, body_bal = http_request("GET", "/api/v1/wallet/balance", token=passenger_token)
        self.assertEqual(st_bal, 200)
        self.assertEqual(Decimal(str(body_bal["balance"])), Decimal("100000.50") - expected_total)

        # 8. Duplicate seat booking must be rejected with 400
        st_dup, body_dup = http_request(
            "POST",
            "/api/v1/bookings",
            {"trip_id": trip_id, "seat_numbers": [seat_a], "payment_method": "WALLET"},
            token=passenger_token,
        )
        self.assertEqual(st_dup, 400, f"Expected 400 for duplicate seat: {body_dup}")

        # 9. GET /api/v1/bookings/my-trips returns the 2 booked seats with QR data
        st_my, my_trips = http_request("GET", "/api/v1/bookings/my-trips", token=passenger_token)
        self.assertEqual(st_my, 200)
        self.assertEqual(len(my_trips), 2)

        booking_a = body_book["bookings"][0]
        booking_b = body_book["bookings"][1]

        # 10. QR verification on booking_a succeeds once, replay fails with 400
        st_v1, body_v1 = http_request(
            "POST",
            "/api/v1/conductor/verify_ticket",
            {"ticket_data": booking_a["qr_code_data"]},
            token=conductor_token,
        )
        self.assertEqual(st_v1, 200, body_v1)
        self.assertTrue(body_v1["valid"], body_v1)
        self.assertNotEqual(body_v1["booking_details"]["route"], "Kampala - Busia")

        st_v1_replay, body_v1_replay = http_request(
            "POST",
            "/api/v1/conductor/verify_ticket",
            {"ticket_data": booking_a["qr_code_data"]},
            token=conductor_token,
        )
        self.assertEqual(st_v1_replay, 400, f"Expected 400 on QR replay: {body_v1_replay}")

        # 11. Manual boarding via booking_id on verify_ticket succeeds once, replay fails with 400
        st_m1, body_m1 = http_request(
            "POST",
            "/api/v1/conductor/verify_ticket",
            {"booking_id": booking_b["id"]},
            token=conductor_token,
        )
        self.assertEqual(st_m1, 200, body_m1)
        self.assertTrue(body_m1["valid"], body_m1)

        st_m1_replay, body_m1_replay = http_request(
            "POST",
            "/api/v1/conductor/verify_ticket",
            {"booking_id": booking_b["id"]},
            token=conductor_token,
        )
        self.assertEqual(st_m1_replay, 400, f"Expected 400 on manual board replay: {body_m1_replay}")

        # 12. Conductor walk-in sell_ticket returns qr_code_data and seat_number, rejects out-of-bounds
        st_sell_oob, _ = http_request(
            "POST",
            "/api/v1/conductor/sell_ticket",
            {
                "trip_id": trip_id,
                "seat_number": 0,
                "passenger_name": "Walkin OOB",
                "passenger_phone": "+256701112233",
                "payment_method": "CASH",
            },
            token=conductor_token,
        )
        self.assertEqual(st_sell_oob, 400)

        st_sell, body_sell = http_request(
            "POST",
            "/api/v1/conductor/sell_ticket",
            {
                "trip_id": trip_id,
                "seat_number": seat_c,
                "passenger_name": "Walkin Passenger",
                "passenger_phone": f"+25677{secrets.randbelow(9000000) + 1000000}",
                "payment_method": "CASH",
            },
            token=conductor_token,
        )
        self.assertEqual(st_sell, 200, body_sell)
        self.assertIn("qr_code_data", body_sell)
        self.assertEqual(body_sell["seat_number"], seat_c)

    def test_04_websocket_tracking_auth_and_paths(self):
        st_clog, body_clog = http_request(
            "POST",
            "/api/v1/auth/login",
            {"phone": "0700000000", "password": "1234"},
        )
        self.assertEqual(st_clog, 200)
        conductor_token = body_clog["access_token"]

        async def run_ws_check():
            async with websockets.connect(f"{WS_BASE_URL}/api/v1/tracking/1") as passenger_ws, \
                       websockets.connect(f"{WS_BASE_URL}/api/v1/tracking/ws/1?token={conductor_token}") as conductor_ws:
                await passenger_ws.send(json.dumps({"lat": 0.3476, "lng": 32.5825}))
                err_msg = json.loads(await asyncio.wait_for(passenger_ws.recv(), timeout=3))
                self.assertIn("error", err_msg)

                await conductor_ws.send(json.dumps({"lat": 0.3476, "lng": 32.5825, "speed": 45.0}))
                bcast = json.loads(await asyncio.wait_for(passenger_ws.recv(), timeout=3))
                self.assertAlmostEqual(bcast["lat"], 0.3476)
                self.assertAlmostEqual(bcast["lng"], 32.5825)

        asyncio.run(run_ws_check())


if __name__ == "__main__":
    unittest.main(verbosity=2)

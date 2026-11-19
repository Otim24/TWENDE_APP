from datetime import datetime, timezone
from decimal import Decimal
import hashlib
import hmac
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from tortoise.exceptions import IntegrityError
from tortoise.transactions import in_transaction

from app.api.deps import get_current_user
from app.core.config import settings
from app.core.security import generate_ticket_qr_data
from app.models.booking_model import Booking, BookingStatus
from app.models.trip_model import Trip, TripStatus
from app.models.user_model import User, UserRole
from app.models.wallet_model import Transaction, TransactionStatus, TransactionType, Wallet

router = APIRouter()

ACTIVE_BOOKING_STATUSES = (BookingStatus.PAID, BookingStatus.USED)


class TicketVerifyRequest(BaseModel):
    ticket_data: Optional[str] = None
    booking_id: Optional[int] = None
    trip_id: Optional[int] = None


class TicketVerifyResponse(BaseModel):
    valid: bool
    message: str
    booking_details: dict | None = None


@router.post("/verify_ticket", response_model=TicketVerifyResponse)
async def verify_ticket(
    request: TicketVerifyRequest,
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")

    target_booking_id: Optional[int] = request.booking_id
    trip_id: Optional[int] = None
    seat_number: Optional[int] = None

    if target_booking_id is None:
        raw_ticket = (request.ticket_data or "").strip()
        if not raw_ticket:
            raise HTTPException(status_code=400, detail="INVALID FORMAT: Missing ticket_data or booking_id")

        if raw_ticket.isdigit():
            target_booking_id = int(raw_ticket)
        else:
            try:
                raw_payload, signature = raw_ticket.split(":")
                parts = raw_payload.split("-")
                if len(parts) != 3 or parts[0] != "TICKET":
                    raise ValueError()
                trip_id = int(parts[1])
                seat_number = int(parts[2])
            except ValueError:
                raise HTTPException(status_code=400, detail="INVALID FORMAT: Invalid ticket data")

            expected_signature = hmac.new(
                settings.SECRET_KEY.encode("utf-8"),
                raw_payload.encode("utf-8"),
                hashlib.sha256,
            ).hexdigest()
            if not hmac.compare_digest(expected_signature, signature):
                raise HTTPException(status_code=400, detail="INVALID SIGNATURE: Ticket may be forged")

    async with in_transaction():
        if target_booking_id is not None:
            booking = await Booking.filter(id=target_booking_id).select_for_update().first()
        else:
            booking = (
                await Booking.filter(trip_id=trip_id, seat_number=seat_number)
                .select_for_update()
                .first()
            )

        if not booking:
            raise HTTPException(status_code=404, detail="INVALID TICKET: Not Found")

        await booking.fetch_related("user", "trip", "trip__route")

        if request.trip_id is not None and booking.trip_id != request.trip_id:
            raise HTTPException(status_code=400, detail="WRONG TRIP: Ticket belongs to a different trip")

        if booking.trip.status not in (TripStatus.SCHEDULED, TripStatus.BOARDING):
            raise HTTPException(
                status_code=400,
                detail=f"INVALID TRIP STATUS: Trip is {booking.trip.status.value}",
            )

        if booking.status == BookingStatus.USED:
            raise HTTPException(status_code=400, detail="ALREADY USED! Ticket scanned previously.")

        if booking.status != BookingStatus.PAID:
            raise HTTPException(status_code=400, detail=f"INVALID STATUS: {booking.status.value}")

        booking.status = BookingStatus.USED
        await booking.save()

        route_name = (
            booking.trip.route.name
            if booking.trip and getattr(booking.trip, "route", None)
            else "Unknown Route"
        )

    return TicketVerifyResponse(
        valid=True,
        message="WELCOME ABOARD! Ticket Verified.",
        booking_details={
            "booking_id": booking.id,
            "passenger": booking.user.full_name if booking.user else "Unknown",
            "seats": 1,
            "seat_number": booking.seat_number,
            "route": route_name,
        },
    )


class SellTicketRequest(BaseModel):
    trip_id: int
    seat_number: int
    passenger_name: str
    passenger_phone: str
    payment_method: str  # CASH, MOMO


@router.post("/sell_ticket")
async def sell_ticket(
    payload: SellTicketRequest,
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")

    method = payload.payment_method.upper()
    if method not in ("CASH", "MOMO", "WALLET"):
        raise HTTPException(status_code=400, detail=f"Unsupported payment method: {payload.payment_method}")

    async with in_transaction():
        trip = await Trip.filter(id=payload.trip_id).select_for_update().first()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")

        await trip.fetch_related("bus", "route")

        if trip.status not in (TripStatus.SCHEDULED, TripStatus.BOARDING):
            raise HTTPException(status_code=400, detail=f"Cannot sell tickets for trip with status {trip.status.value}")

        if trip.departure_time < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Cannot sell tickets for a past trip")

        valid_seats = set(trip.bus.get_valid_seats()) if trip.bus else set(range(1, 61))
        if payload.seat_number not in valid_seats:
            raise HTTPException(
                status_code=400,
                detail=f"Seat {payload.seat_number} is out of bounds for this bus",
            )

        existing = (
            await Booking.filter(trip=trip, seat_number=payload.seat_number)
            .select_for_update()
            .first()
        )
        if existing and existing.status in ACTIVE_BOOKING_STATUSES:
            raise HTTPException(status_code=400, detail=f"Seat {payload.seat_number} is already taken")

        user = await User.filter(phone=payload.passenger_phone).select_for_update().first()
        if not user:
            try:
                user = await User.create(
                    phone=payload.passenger_phone,
                    full_name=payload.passenger_name,
                    role=UserRole.PASSENGER,
                    password_hash="",
                )
            except IntegrityError:
                user = await User.get(phone=payload.passenger_phone)

        wallet = await Wallet.filter(user=user).select_for_update().first()
        if not wallet:
            wallet = await Wallet.create(user=user, balance=Decimal("0.00"))
            wallet = await Wallet.filter(id=wallet.id).select_for_update().first()

        ticket_price = Decimal(str(trip.price))

        if method in ("MOMO", "WALLET"):
            if Decimal(str(wallet.balance)) < ticket_price:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient wallet balance. Required: {ticket_price}, Available: {wallet.balance}",
                )

            wallet.balance = Decimal(str(wallet.balance)) - ticket_price
            await wallet.save()

            await Transaction.create(
                wallet=wallet,
                amount=ticket_price,
                type=TransactionType.PAYMENT,
                status=TransactionStatus.COMPLETED,
                reference=f"TICKET-{trip.id}-{payload.seat_number}",
            )
        elif method == "CASH":
            await Transaction.create(
                wallet=wallet,
                amount=ticket_price,
                type=TransactionType.PAYMENT,
                status=TransactionStatus.COMPLETED,
                reference=f"CASH-{trip.id}-{payload.seat_number}",
            )

        qr_code_data = generate_ticket_qr_data(trip.id, payload.seat_number)

        if existing:
            existing.user = user
            existing.status = BookingStatus.PAID
            existing.qr_code_data = qr_code_data
            await existing.save()
            booking = existing
        else:
            try:
                booking = await Booking.create(
                    trip=trip,
                    user=user,
                    seat_number=payload.seat_number,
                    status=BookingStatus.PAID,
                    qr_code_data=qr_code_data,
                )
            except IntegrityError:
                raise HTTPException(
                    status_code=400,
                    detail=f"Seat {payload.seat_number} was just taken by another transaction",
                )

    return {
        "success": True,
        "booking_id": booking.id,
        "seat_number": booking.seat_number,
        "qr_code_data": booking.qr_code_data,
        "message": f"Ticket Sold! Seat {payload.seat_number} Assigned.",
        "payment_method": method,
    }


class TripResponse(BaseModel):
    id: int
    route_name: str
    bus_plate: str
    price: Decimal
    departure_time: str
    status: str
    occupied_seats: int
    total_seats: int


@router.get("/trips", response_model=list[TripResponse])
async def get_trips(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")

    trips = (
        await Trip.filter(status__in=[TripStatus.SCHEDULED, TripStatus.BOARDING])
        .prefetch_related("bus", "route", "bookings")
        .all()
    )

    response = []
    for trip in trips:
        valid_seats = set(trip.bus.get_valid_seats()) if trip.bus else set(range(1, 61))
        total = len(valid_seats)
        occupied = len(
            [
                b
                for b in trip.bookings
                if b.status in ACTIVE_BOOKING_STATUSES and b.seat_number in valid_seats
            ]
        )
        raw_status = trip.status
        status_str = getattr(raw_status, "value", str(raw_status))
        r_name = trip.route.name if trip.route else "Unknown Route"
        b_plate = trip.bus.plate_number if trip.bus else "Unknown Bus"
        t_price = Decimal(str(trip.price)) if trip.price is not None else Decimal("0.00")

        response.append(
            TripResponse(
                id=trip.id,
                route_name=str(r_name),
                bus_plate=str(b_plate),
                price=t_price,
                departure_time=str(trip.departure_time or ""),
                status=str(status_str),
                occupied_seats=occupied,
                total_seats=total,
            )
        )

    return response


class ManifestItem(BaseModel):
    seat_number: int
    status: str  # AVAILABLE, BOOKED, OCCUPIED
    passenger_name: str | None = None
    passenger_phone: str | None = None
    booking_id: int | None = None


@router.get("/trips/{trip_id}/manifest", response_model=list[ManifestItem])
async def get_trip_manifest(trip_id: int, current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")

    trip = await Trip.get_or_none(id=trip_id).prefetch_related("bus")
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    bookings = await Booking.filter(trip_id=trip_id).prefetch_related("user")
    booking_map = {b.seat_number: b for b in bookings}

    seats_to_map = trip.bus.get_valid_seats() if trip.bus else list(range(1, 61))
    manifest = []

    for i in seats_to_map:
        booking = booking_map.get(i)
        item_status = "AVAILABLE"
        name = None
        phone = None
        b_id = None

        if booking:
            b_id = booking.id
            if booking.status == BookingStatus.USED:
                item_status = "OCCUPIED"
                name = booking.user.full_name if booking.user else "Unknown"
                phone = booking.user.phone if booking.user else None
            elif booking.status == BookingStatus.PAID:
                item_status = "BOOKED"
                name = booking.user.full_name if booking.user else "Unknown"
                phone = booking.user.phone if booking.user else None
            elif booking.status == BookingStatus.LOCKED:
                item_status = "BOOKED"
                name = "Reserved"

        manifest.append(
            ManifestItem(
                seat_number=i,
                status=item_status,
                passenger_name=name,
                passenger_phone=phone,
                booking_id=b_id,
            )
        )

    return manifest

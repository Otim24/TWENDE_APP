from datetime import datetime, timezone
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from tortoise.transactions import in_transaction

from app.api.deps import get_current_user
from app.core.security import generate_ticket_qr_data
from app.models import Trip, TripStatus, User
from app.models.booking_model import Booking, BookingStatus
from app.models.wallet_model import Transaction, TransactionStatus, TransactionType, Wallet

router = APIRouter()

ACTIVE_BOOKING_STATUSES = (BookingStatus.PAID, BookingStatus.USED)


class CreateBookingRequest(BaseModel):
    trip_id: int
    seat_numbers: list[int] = Field(..., min_length=1)
    payment_method: str = "WALLET"


@router.get("/my-trips")
async def get_my_trips(current_user: User = Depends(get_current_user)):
    """
    Get all paid or used bookings for the authenticated user.
    """
    bookings = (
        await Booking.filter(
            user=current_user,
            status__in=ACTIVE_BOOKING_STATUSES,
        )
        .prefetch_related("trip", "trip__route", "trip__bus")
        .order_by("-trip__departure_time")
    )

    results = []
    for booking in bookings:
        results.append(
            {
                "id": booking.id,
                "seat_number": booking.seat_number,
                "status": booking.status.value,
                "qr_code_data": booking.qr_code_data,
                "trip": {
                    "id": booking.trip.id,
                    "route_name": booking.trip.route.name,
                    "origin": booking.trip.route.origin,
                    "destination": booking.trip.route.destination,
                    "departure_time": (
                        booking.trip.departure_time.isoformat()
                        if booking.trip.departure_time
                        else None
                    ),
                    "arrival_time": (
                        booking.trip.arrival_time.isoformat()
                        if booking.trip.arrival_time
                        else None
                    ),
                    "price": booking.trip.price,
                    "status": booking.trip.status.value,
                    "bus_plate": booking.trip.bus.plate_number,
                },
            }
        )
    return results


@router.get("/search")
async def search_trips(
    from_loc: str = Query(..., alias="from"),
    to_loc: str = Query(..., alias="to"),
    date: str = Query(...),
):
    """
    Search for trips by Origin, Destination and Date (YYYY-MM-DD).
    """
    try:
        search_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    trips = await Trip.filter(
        route__origin__iexact=from_loc,
        route__destination__iexact=to_loc,
        departure_time__gte=datetime.combine(search_date, datetime.min.time()).replace(
            tzinfo=timezone.utc
        ),
        departure_time__lte=datetime.combine(search_date, datetime.max.time()).replace(
            tzinfo=timezone.utc
        ),
        status__in=[TripStatus.SCHEDULED, TripStatus.BOARDING],
    ).prefetch_related("route", "bus", "bookings")

    results = []
    for trip in trips:
        valid_seats = set(trip.bus.get_valid_seats()) if trip.bus else set(range(1, 61))
        capacity = len(valid_seats)
        active_bookings_count = len(
            [
                b
                for b in trip.bookings
                if b.status in ACTIVE_BOOKING_STATUSES and b.seat_number in valid_seats
            ]
        )
        available_seats = max(0, capacity - active_bookings_count)

        results.append(
            {
                "id": trip.id,
                "route_name": trip.route.name,
                "origin": trip.route.origin,
                "destination": trip.route.destination,
                "departure_time": trip.departure_time,
                "arrival_time": trip.arrival_time,
                "price": trip.price,
                "bus_plate": trip.bus.plate_number,
                "total_seats": capacity,
                "available_seats": available_seats,
            }
        )

    return results


@router.get("/{trip_id}")
async def get_trip_details(trip_id: int):
    """
    Get detailed trip info, including booked seats, seat layout, and stops timeline.
    """
    trip = await Trip.get_or_none(id=trip_id).prefetch_related("route", "bus", "bookings")

    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    seat_layout = trip.bus.get_valid_seats() if trip.bus else list(range(1, 61))
    valid_seat_set = set(seat_layout)
    booked_seats = sorted(
        b.seat_number
        for b in trip.bookings
        if b.status in ACTIVE_BOOKING_STATUSES and b.seat_number in valid_seat_set
    )
    capacity = len(seat_layout)
    available_seats = max(0, capacity - len(booked_seats))

    return {
        "id": trip.id,
        "route_name": trip.route.name,
        "origin": trip.route.origin,
        "destination": trip.route.destination,
        "departure_time": trip.departure_time,
        "arrival_time": trip.arrival_time,
        "price": trip.price,
        "status": trip.status.value,
        "total_seats": capacity,
        "available_seats": available_seats,
        "booked_seats": booked_seats,
        "seat_layout": seat_layout,
        "bus": {
            "plate": trip.bus.plate_number,
            "capacity": capacity,
        },
        "timeline": trip.route.stops,
    }


@router.post("")
@router.post("/")
async def create_booking(
    payload: CreateBookingRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Create one or more seat bookings for an authenticated user with exact Decimal math and row-level locks.
    """
    seat_numbers = list(dict.fromkeys(payload.seat_numbers))
    if not seat_numbers:
        raise HTTPException(status_code=400, detail="At least one seat number is required")

    method = payload.payment_method.upper()
    if method not in ("WALLET", "MOMO"):
        raise HTTPException(status_code=400, detail=f"Unsupported payment method: {payload.payment_method}")

    async with in_transaction():
        trip = await Trip.filter(id=payload.trip_id).select_for_update().first()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")

        await trip.fetch_related("bus", "route")

        if trip.status not in (TripStatus.SCHEDULED, TripStatus.BOARDING):
            raise HTTPException(status_code=400, detail=f"Trip is not open for booking (status: {trip.status.value})")

        if trip.departure_time < datetime.now(timezone.utc):
            raise HTTPException(status_code=400, detail="Cannot book seats for a past trip")

        valid_seats = set(trip.bus.get_valid_seats()) if trip.bus else set(range(1, 61))
        for seat_num in seat_numbers:
            if seat_num not in valid_seats:
                raise HTTPException(
                    status_code=400,
                    detail=f"Seat {seat_num} is out of bounds for this bus",
                )

        existing_rows = (
            await Booking.filter(trip=trip, seat_number__in=seat_numbers)
            .select_for_update()
            .all()
        )
        existing_by_seat = {b.seat_number: b for b in existing_rows}
        for seat_num in seat_numbers:
            existing_b = existing_by_seat.get(seat_num)
            if existing_b and existing_b.status in ACTIVE_BOOKING_STATUSES:
                raise HTTPException(status_code=400, detail=f"Seat {seat_num} is already taken")

        unit_price = Decimal(str(trip.price))
        total_price = unit_price * Decimal(len(seat_numbers))

        wallet = await Wallet.filter(user=current_user).select_for_update().first()
        if not wallet:
            wallet = await Wallet.create(user=current_user, balance=Decimal("0.00"))
            wallet = await Wallet.filter(id=wallet.id).select_for_update().first()

        if Decimal(str(wallet.balance)) < total_price:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient wallet balance. Required: {total_price}, Available: {wallet.balance}",
            )

        wallet.balance = Decimal(str(wallet.balance)) - total_price
        await wallet.save()

        seats_label = ",".join(str(s) for s in seat_numbers)
        await Transaction.create(
            wallet=wallet,
            amount=total_price,
            type=TransactionType.PAYMENT,
            status=TransactionStatus.COMPLETED,
            reference=f"BOOKING-{trip.id}-{seats_label}",
        )

        created_bookings = []
        for seat_num in seat_numbers:
            qr_code_data = generate_ticket_qr_data(trip.id, seat_num)
            existing_b = existing_by_seat.get(seat_num)
            if existing_b:
                existing_b.user = current_user
                existing_b.status = BookingStatus.PAID
                existing_b.qr_code_data = qr_code_data
                await existing_b.save()
                booking_obj = existing_b
            else:
                booking_obj = await Booking.create(
                    trip=trip,
                    user=current_user,
                    seat_number=seat_num,
                    status=BookingStatus.PAID,
                    qr_code_data=qr_code_data,
                )

            created_bookings.append(
                {
                    "id": booking_obj.id,
                    "trip_id": trip.id,
                    "seat_number": booking_obj.seat_number,
                    "status": booking_obj.status.value,
                    "qr_code_data": booking_obj.qr_code_data,
                    "price": unit_price,
                }
            )

    return {
        "success": True,
        "trip_id": trip.id,
        "route_name": trip.route.name,
        "payment_method": method,
        "total_price": total_price,
        "bookings": created_bookings,
    }

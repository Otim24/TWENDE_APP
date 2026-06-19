from fastapi import APIRouter, HTTPException, Depends
from app.models.booking_model import Booking, BookingStatus
from app.models.trip_model import Trip, TripStatus
from app.models.user_model import User, UserRole
from app.api.deps import get_current_user
from pydantic import BaseModel

router = APIRouter()

class TicketVerifyRequest(BaseModel):
    ticket_data: str

class TicketVerifyResponse(BaseModel):
    valid: bool
    message: str
    booking_details: dict | None = None

@router.post("/verify_ticket", response_model=TicketVerifyResponse)
async def verify_ticket(request: TicketVerifyRequest, current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")
    booking_id_str = request.ticket_data
    
    # Basic parsing if needed. For now assuming ticket_data Is the ID.
    try:
        booking_id = int(booking_id_str)
    except ValueError:
        return TicketVerifyResponse(valid=False, message="INVALID FORMAT: Ticket ID must be a number")

    booking = await Booking.get_or_none(id=booking_id).prefetch_related("user", "trip")
    
    if not booking:
        return TicketVerifyResponse(valid=False, message="INVALID TICKET: Not Found")

    if booking.status == BookingStatus.USED:
        return TicketVerifyResponse(valid=False, message="ALREADY USED! Ticket scanned previously.")

    if booking.status != BookingStatus.PAID:
        return TicketVerifyResponse(valid=False, message=f"INVALID STATUS: {booking.status}")

    # If Valid and PAID, mark as USED
    booking.status = BookingStatus.USED
    await booking.save()
    

    return TicketVerifyResponse(
        valid=True, 
        message="WELCOME ABOARD! Ticket Verified.",
        booking_details={
            "passenger": booking.user.full_name if booking.user else "Unknown",
            "seats": 1, 
            "seat_number": booking.seat_number,
            "route": "Kampala - Busia" 
        }
    )

class SellTicketRequest(BaseModel):
    trip_id: int
    seat_number: int
    passenger_name: str
    passenger_phone: str
    payment_method: str # CASH, MOMO

@router.post("/sell_ticket")
async def sell_ticket(payload: SellTicketRequest, current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")
    from tortoise.transactions import in_transaction
    from app.models.wallet_model import Wallet, Transaction, TransactionType, TransactionStatus
    from tortoise.exceptions import IntegrityError
    import hmac, hashlib
    from app.core.config import settings

    # 1. Check Trip
    trip = await Trip.get_or_none(id=payload.trip_id)
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    from datetime import datetime, timezone
    if trip.departure_time < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Cannot sell tickets for a past trip")

    # 2. Check Seat Availability
    existing = await Booking.filter(trip=trip, seat_number=payload.seat_number).exists()
    if existing:
        raise HTTPException(status_code=400, detail=f"Seat {payload.seat_number} is already taken")

    # 3. Find or Create User (Walk-in)
    user = await User.get_or_none(phone=payload.passenger_phone)
    if not user:
        # Create Walk-in User
        user = await User.create(
            phone=payload.passenger_phone,
            full_name=payload.passenger_name,
            role=UserRole.PASSENGER,
            password_hash="" # Walk-in doesn't have password yet
        )
        await Wallet.create(user=user)

    # 4. Process Payment & Create Booking inside a transaction
    async with in_transaction():
        ticket_price = trip.price  # DecimalField from the Trip model

        if payload.payment_method == "MOMO":
            # For MOMO, deduct from wallet balance
            wallet = await Wallet.get_or_none(user=user)
            if not wallet:
                raise HTTPException(status_code=400, detail="Wallet not found for this user")
            if wallet.balance < ticket_price:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient wallet balance. Required: {ticket_price}, Available: {wallet.balance}"
                )

            wallet.balance -= ticket_price
            await wallet.save()

            # Record the deduction transaction
            await Transaction.create(
                wallet=wallet,
                amount=ticket_price,
                type=TransactionType.PAYMENT,
                status=TransactionStatus.COMPLETED,
                reference=f"TICKET-{trip.id}-{payload.seat_number}"
            )

        elif payload.payment_method == "CASH":
            # Cash is collected physically by the conductor.
            # Record a transaction for audit trail only.
            wallet = await Wallet.get_or_none(user=user)
            if wallet:
                await Transaction.create(
                    wallet=wallet,
                    amount=ticket_price,
                    type=TransactionType.PAYMENT,
                    status=TransactionStatus.COMPLETED,
                    reference=f"CASH-{trip.id}-{payload.seat_number}"
                )
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported payment method: {payload.payment_method}")

        # 5. Create Booking (only reached if payment logic above passed)
        raw_payload = f"TICKET-{trip.id}-{payload.seat_number}"
        signature = hmac.new(settings.SECRET_KEY.encode(), raw_payload.encode(), hashlib.sha256).hexdigest()
        qr_code_data = f"{raw_payload}:{signature}"
        
        try:
            booking = await Booking.create(
                trip=trip,
                user=user,
                seat_number=payload.seat_number,
                status=BookingStatus.PAID,
                qr_code_data=qr_code_data
            )
        except IntegrityError:
            raise HTTPException(status_code=400, detail=f"Seat {payload.seat_number} was just taken by another transaction")

    return {
        "success": True, 
        "booking_id": booking.id, 
        "message": f"Ticket Sold! Seat {payload.seat_number} Assigned.",
        "payment_method": payload.payment_method
    }



class TripResponse(BaseModel):
    id: int
    route_name: str
    departure_time: str
    status: str
    occupied_seats: int
    total_seats: int

@router.get("/trips", response_model=list[TripResponse])
async def get_trips(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.CONDUCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")
    # In real app, filter by conductor assignment. 
    # For MVP, returning all SCHEDULED or BOARDING trips.
    trips = await Trip.filter(
        status__in=[TripStatus.SCHEDULED, TripStatus.BOARDING]
    ).prefetch_related("bus", "route", "bookings").all()
    
    response = []
    for trip in trips:
        try:
            # Safe Access Helpers
            def safe_get(obj, attr, default=None):
                val = getattr(obj, attr, default)
                if val is None: return default
                return val

            # Occupancy
            occupied = 0
            bookings = safe_get(trip, "bookings", [])
            if bookings:
                 occupied = len([b for b in bookings if getattr(b, "status", None) in [BookingStatus.PAID, BookingStatus.USED]])
            
            # Status
            raw_status = safe_get(trip, "status", "SCHEDULED")
            status_str = getattr(raw_status, "value", str(raw_status))

            # Route Name
            route_obj = safe_get(trip, "route", None)
            r_name = safe_get(route_obj, "name", "Unknown Route")

            # Bus
            bus_obj = safe_get(trip, "bus", None)
            total = safe_get(bus_obj, "total_seats", 60)

            response.append(TripResponse(
                id=trip.id,
                route_name=str(r_name),
                departure_time=str(safe_get(trip, "departure_time", "")),
                status=str(status_str),
                occupied_seats=occupied,
                total_seats=total
            ))
        except Exception as e:
            print(f"Error processing trip {trip.id}: {e}")
            continue # Skip bad records instead of crashing everything

    return response

class ManifestItem(BaseModel):
    seat_number: int
    status: str # AVAILABLE, BOOKED, OCCUPIED
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
    
    # Map bookings by seat number
    booking_map = {b.seat_number: b for b in bookings}
    
    total_seats = trip.bus.total_seats if trip.bus else 60
    manifest = []
    
    for i in range(1, total_seats + 1):
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
                 # Depending on business logic, maybe show as BOOKED or AVAILABLE?
                 # Let's show as BOOKED but maybe different color in future.
                 item_status = "BOOKED" 
                 name = "Reserved"
        
        manifest.append(ManifestItem(
            seat_number=i,
            status=item_status,
            passenger_name=name,
            passenger_phone=phone,
            booking_id=b_id
        ))
        
    return manifest

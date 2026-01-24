from fastapi import APIRouter, HTTPException
from app.models.booking_model import Booking, BookingStatus
from app.models.trip_model import Trip, TripStatus
from pydantic import BaseModel

router = APIRouter()

class TicketVerifyRequest(BaseModel):
    ticket_data: str

class TicketVerifyResponse(BaseModel):
    valid: bool
    message: str
    booking_details: dict | None = None

@router.post("/verify_ticket", response_model=TicketVerifyResponse)
async def verify_ticket(request: TicketVerifyRequest):
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
async def sell_ticket(payload: SellTicketRequest):
    # 1. Check Trip
    trip = await Trip.get_or_none(id=payload.trip_id)
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # 2. Check Seat Availability
    existing = await Booking.filter(trip=trip, seat_number=payload.seat_number).exists()
    if existing:
        raise HTTPException(status_code=400, detail=f"Seat {payload.seat_number} is already taken")

    # 3. Find or Create User (Walk-in)
    from app.models.user_model import User, UserRole
    from app.models.wallet_model import Wallet
    
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
    
    # 4. Create Booking
    # For MVP, assuming payment was successful locally (Cash/MoMo)
    booking = await Booking.create(
        trip=trip,
        user=user,
        seat_number=payload.seat_number,
        status=BookingStatus.PAID, # Auto-mark as PAID
        qr_code_data=f"TICKET-{trip.id}-{payload.seat_number}" # Simple QR logic
    )

    return {
        "success": True, 
        "booking_id": booking.id, 
        "message": f"Ticket Sold! Seat {payload.seat_number} Assigned."
    }



class TripResponse(BaseModel):
    id: int
    route_name: str
    departure_time: str
    status: str
    occupied_seats: int
    total_seats: int

@router.get("/trips", response_model=list[TripResponse])
async def get_trips():
    # In real app, filter by conductor assignment. 
    # For MVP, returning all SCHEDULED or BOARDING trips.
    # Remove prefetch to avoid "route_id does not exist" if DB schema is out of sync
    trips = await Trip.filter(
        status__in=[TripStatus.SCHEDULED, TripStatus.BOARDING]
    ).all()
    
    # Manually fetch to be safe
    for t in trips:
        await t.fetch_related("bus", "route", "bookings")
    
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
async def get_trip_manifest(trip_id: int):
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

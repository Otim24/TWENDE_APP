from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from app.api.deps import get_current_user
from app.models import Trip, TripStatus, User
from app.models.trip_model import Route
from app.models.booking_model import Booking, BookingStatus

router = APIRouter()

@router.get("/my-trips")
async def get_my_trips(current_user: User = Depends(get_current_user)):
    """
    Get all bookings for the authenticated user.
    """
    bookings = await Booking.filter(
        user=current_user,
        status__in=[BookingStatus.PAID, BookingStatus.USED] # only return paid or used tickets
    ).prefetch_related("trip", "trip__route", "trip__bus").order_by("-trip__departure_time")

    results = []
    for booking in bookings:
        results.append({
            "id": booking.id,
            "seat_number": booking.seat_number,
            "status": booking.status.value,
            "qr_code_data": booking.qr_code_data,
            "trip": {
                "id": booking.trip.id,
                "origin": booking.trip.route.origin,
                "destination": booking.trip.route.destination,
                "departure_time": booking.trip.departure_time.isoformat() if booking.trip.departure_time else None,
                "arrival_time": booking.trip.arrival_time.isoformat() if booking.trip.arrival_time else None,
                "price": booking.trip.price,
                "status": booking.trip.status.value,
                "bus_plate": booking.trip.bus.plate_number,
            }
        })
    return results

@router.get("/search")
async def search_trips(
    from_loc: str = Query(..., alias="from"),
    to_loc: str = Query(..., alias="to"),
    date: str = Query(...) # Format YYYY-MM-DD
):
    """
    Search for trips by Origin, Destination and Date.
    Strictly filters for future trips (or trips on that day if today).
    """
    try:
        search_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    # Fetch trips matching route criteria
    # Note: We filter by the Route's origin/destination via the relation
    trips = await Trip.filter(
        route__origin__iexact=from_loc,
        route__destination__iexact=to_loc,
        departure_time__gte=datetime.combine(search_date, datetime.min.time()),
        departure_time__lte=datetime.combine(search_date, datetime.max.time()),
        status=TripStatus.SCHEDULED
    ).prefetch_related("route", "bus")
    
    results = []
    for trip in trips:
        results.append({
            "id": trip.id,
            "origin": trip.route.origin,
            "destination": trip.route.destination,
            "departure_time": trip.departure_time,
            "arrival_time": trip.arrival_time,
            "price": trip.price,
            "bus_plate": trip.bus.plate_number,
            "total_seats": trip.bus.total_seats,
            # "available_seats": Calculate from bookings count (todo)
        })
    
    return results

@router.get("/{trip_id}")
async def get_trip_details(trip_id: int):
    """
    Get detailed trip info, including the calculated timeline from the Route.
    """
    trip = await Trip.get_or_none(id=trip_id).prefetch_related("route", "bus")
    
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
        
    return {
        "id": trip.id,
        "origin": trip.route.origin,
        "destination": trip.route.destination,
        "departure_time": trip.departure_time,
        "arrival_time": trip.arrival_time,
        "price": trip.price,
        "bus": {
            "plate": trip.bus.plate_number,
            "capacity": trip.bus.total_seats
        },
        "timeline": trip.route.stops # The structured timeline audit requirement
    }

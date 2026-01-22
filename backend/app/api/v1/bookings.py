from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from app.api.deps import get_current_user
from app.models import Trip, TripStatus, User
from app.models.trip_model import Route

router = APIRouter()

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

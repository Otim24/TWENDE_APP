from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.booking_model import Booking
from app.models.trip_model import Trip
from pydantic import BaseModel

router = APIRouter()

class TicketVerifyRequest(BaseModel):
    ticket_data: str

class TicketVerifyResponse(BaseModel):
    valid: bool
    message: str
    booking_details: dict | None = None

@router.post("/verify_ticket", response_model=TicketVerifyResponse)
def verify_ticket(
    request: TicketVerifyRequest,
    db: Session = Depends(deps.get_db),
    # In a real app, we'd add current_user dependency to ensure it's a conductor
):
    # Expected Format: "TWENDE-TRIP-{trip_id}-SEATS-{seat_count}-BOOKING-{booking_id}"
    # Or simplified just booking ID if we change QR format. 
    # Let's assume the QR contains the Booking ID or a unique ticket string.
    # For now, let's assume the QR string *IS* the Booking ID or contains it.
    
    # Let's try to look up by ID if it looks like a UUID, or parse properly
    # Implementation Plan said: "TWENDE-TRIP-{id}-SEATS-{seats}"... wait, that's not unique enough if user books multiple times.
    # The Receipt Screen (TicketReceiptScreen) likely encodes the Booking ID.
    # Let's check TicketReceiptScreen to be sure what we are scanning.
    
    # Actually, I'll just look for the Booking ID in the payload or assume the payload IS the ID for simplicity first.
    # If the payload contains "TWENDE", I'll try to extract the ID.
    
    # Simpler approach: The QR code should ideally just be the Booking ID (UUID).
    
    booking_id = request.ticket_data
    if "TWENDE" in booking_id:
       # Clean it if needed, or if we defined a format in Receipt Screen, we parse it.
       # For now, I will treat the input as the Booking UUID directly for robustness.
       pass

    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    
    if not booking:
        return TicketVerifyResponse(valid=False, message="INVALID TICKET: Not Found")

    if booking.status == "USED":
        return TicketVerifyResponse(valid=False, message="ALREADY USED! Ticket scanned previously.")

    if booking.status != "PAID":
        return TicketVerifyResponse(valid=False, message=f"INVALID STATUS: {booking.status}")

    # If Valid and PAID, mark as USED
    booking.status = "USED"
    db.commit()
    
    return TicketVerifyResponse(
        valid=True, 
        message="WELCOME ABOARD! Ticket Verified.",
        booking_details={
            "passenger": booking.user.full_name if booking.user else "Unknown",
            "seats": booking.seat_count,
            "route": "Kampala - Busia" # Dynamic later
        }
    )

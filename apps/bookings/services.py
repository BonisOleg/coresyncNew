"""
Booking business logic with race condition protection.
Thread-safe booking creation with slot validation and locking.
"""

from __future__ import annotations

import logging
from datetime import date, time
from typing import TYPE_CHECKING

from django.db import transaction
from django.utils import timezone

from .models import Booking, BookingSlot

if TYPE_CHECKING:
    from apps.guests.models import Guest

logger = logging.getLogger(__name__)


class BookingError(Exception):
    """Base exception for booking errors."""

    pass


class SlotNotAvailableError(BookingError):
    """Raised when requested slot is not available."""

    pass


class SlotNotFoundError(BookingError):
    """Raised when requested slot doesn't exist."""

    pass


def create_booking_safe(
    guest: Guest,
    date_value: date | str,
    time_start: time | str,
    time_end: time | str = "23:00",
    source: str = Booking.Source.WEB_CHAT,
    notes: str = "",
) -> Booking:
    """
    Create a booking with race condition protection.
    
    This function uses database-level locking to prevent double-booking.
    It's safe to call from multiple processes/threads simultaneously.
    
    Args:
        guest: Guest making the booking
        date_value: Booking date (date object or YYYY-MM-DD string)
        time_start: Start time (time object or HH:MM string)
        time_end: End time (time object or HH:MM string)
        source: Booking source (WEB_CHAT, VOICE, FLUTTER, ADMIN)
        notes: Additional notes
        
    Returns:
        Created Booking object
        
    Raises:
        SlotNotFoundError: If no matching slot exists
        SlotNotAvailableError: If slot is already booked or unavailable
        
    Example:
        >>> from apps.guests.models import Guest
        >>> guest = Guest.objects.get(phone="+380123456789")
        >>> booking = create_booking_safe(
        ...     guest=guest,
        ...     date_value="2026-03-21",
        ...     time_start="18:00",
        ...     source=Booking.Source.VOICE
        ... )
    """
    # Convert string to date/time if needed
    if isinstance(date_value, str):
        from datetime import datetime
        date_value = datetime.strptime(date_value, "%Y-%m-%d").date()
    
    if isinstance(time_start, str):
        from datetime import datetime
        time_start = datetime.strptime(time_start, "%H:%M").time()
    
    if isinstance(time_end, str):
        from datetime import datetime
        time_end = datetime.strptime(time_end, "%H:%M").time()

    # Use database transaction with row-level locking
    with transaction.atomic():
        # Find and lock the slot (SELECT FOR UPDATE)
        slot = (
            BookingSlot.objects.select_for_update()
            .filter(
                date=date_value,
                time_start=time_start,
            )
            .first()
        )

        if not slot:
            raise SlotNotFoundError(
                f"No booking slot found for {date_value} at {time_start}"
            )

        # Check if slot is available
        if not slot.is_available:
            raise SlotNotAvailableError(
                f"Slot {date_value} {time_start} is marked as unavailable"
            )

        # Check if slot already has a booking
        existing_booking = Booking.objects.filter(
            date=date_value,
            time_start=time_start,
            status__in=[
                Booking.Status.PENDING,
                Booking.Status.CONFIRMED,
            ],
        ).exists()

        if existing_booking:
            raise SlotNotAvailableError(
                f"Slot {date_value} {time_start} is already booked"
            )

        # Create booking
        booking = Booking.objects.create(
            guest=guest,
            slot=slot,
            date=date_value,
            time_start=time_start,
            time_end=time_end,
            status=Booking.Status.PENDING,
            source=source,
            notes=notes,
        )

        logger.info(
            "Booking created safely: %s for guest %s at %s %s",
            booking.id,
            guest.phone,
            date_value,
            time_start,
        )

        return booking


def check_slot_availability(
    date_value: date | str,
    time_start: time | str,
) -> dict[str, bool | str]:
    """
    Check if a slot is available for booking.
    
    Args:
        date_value: Booking date
        time_start: Start time
        
    Returns:
        Dict with 'available' (bool) and 'reason' (str) keys
        
    Example:
        >>> result = check_slot_availability("2026-03-21", "18:00")
        >>> if result['available']:
        ...     print("Slot is free!")
    """
    # Convert string to date/time if needed
    if isinstance(date_value, str):
        from datetime import datetime
        date_value = datetime.strptime(date_value, "%Y-%m-%d").date()
    
    if isinstance(time_start, str):
        from datetime import datetime
        time_start = datetime.strptime(time_start, "%H:%M").time()

    # Check if slot exists
    slot = BookingSlot.objects.filter(
        date=date_value,
        time_start=time_start,
    ).first()

    if not slot:
        return {
            "available": False,
            "reason": f"No slot configured for {date_value} at {time_start}",
        }

    if not slot.is_available:
        return {
            "available": False,
            "reason": "Slot is blocked by admin",
        }

    # Check existing bookings
    existing = Booking.objects.filter(
        date=date_value,
        time_start=time_start,
        status__in=[
            Booking.Status.PENDING,
            Booking.Status.CONFIRMED,
        ],
    ).exists()

    if existing:
        return {
            "available": False,
            "reason": "Slot is already booked",
        }

    return {
        "available": True,
        "reason": "Slot is available",
    }

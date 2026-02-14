"""
Booking utility functions — Cal.com sync.
"""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

import httpx
from django.conf import settings

if TYPE_CHECKING:
    from .models import Booking

logger = logging.getLogger(__name__)


def sync_booking_to_calcom(booking: Booking) -> bool:
    """
    Create or update a booking event in Cal.com.
    Returns True on success, False on failure.
    """
    api_key = settings.CALCOM_API_KEY
    if not api_key:
        logger.warning("CALCOM_API_KEY not configured; skipping sync.")
        return False

    base_url = "https://api.cal.com/v1"

    payload = {
        "eventTypeId": 1,  # Placeholder — configure per actual cal.com setup
        "start": f"{booking.date}T{booking.time_start}",
        "end": f"{booking.date}T{booking.time_end}",
        "name": booking.guest.full_name or "Guest",
        "email": booking.guest.email or "noreply@coresync.com",
        "metadata": {
            "booking_id": str(booking.id),
            "source": booking.source,
        },
    }

    try:
        if booking.calcom_booking_uid:
            # Update existing
            response = httpx.patch(
                f"{base_url}/bookings/{booking.calcom_booking_uid}",
                params={"apiKey": api_key},
                json=payload,
                timeout=10,
            )
        else:
            # Create new
            response = httpx.post(
                f"{base_url}/bookings",
                params={"apiKey": api_key},
                json=payload,
                timeout=10,
            )

        response.raise_for_status()
        data = response.json()

        # Store cal.com references
        booking.calcom_booking_uid = data.get("uid", "")
        booking.calcom_event_id = str(data.get("id", ""))
        booking.save(update_fields=["calcom_booking_uid", "calcom_event_id"])

        logger.info("Synced booking %s to Cal.com (uid=%s)", booking.id, booking.calcom_booking_uid)
        return True

    except httpx.HTTPError as exc:
        logger.error("Cal.com sync failed for booking %s: %s", booking.id, exc)
        return False

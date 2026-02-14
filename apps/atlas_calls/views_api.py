"""
Atlas.AI webhook handler and API endpoints for Atlas Actions.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging

from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from apps.bookings.models import Booking
from apps.bookings.services import BookingError, check_slot_availability, create_booking_safe
from apps.bookings.utils import sync_booking_to_calcom
from apps.guests.models import Guest

from .models import CallRecord

logger = logging.getLogger(__name__)


@csrf_exempt
@require_POST
def atlas_webhook(request: HttpRequest) -> HttpResponse:
    """
    Handle Atlas.AI webhook events — call status, transcript, outcome.
    Links calls to guests by phone number and creates bookings if detected.
    """
    # Verify webhook signature
    secret = settings.ATLAS_WEBHOOK_SECRET
    if secret:
        signature = request.headers.get("X-Atlas-Signature", "")
        expected = hmac.new(
            secret.encode(),
            request.body,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(signature, expected):
            return HttpResponse("Invalid signature", status=403)

    try:
        payload = json.loads(request.body)
    except json.JSONDecodeError:
        return HttpResponse("Invalid JSON", status=400)

    atlas_call_id = payload.get("call_id", "")
    phone_number = payload.get("phone_number", "")
    call_status = payload.get("status", "")
    transcript = payload.get("transcript", "")
    outcome = payload.get("outcome", "")
    duration = payload.get("duration_seconds", 0)
    direction = payload.get("direction", "outbound")

    if not atlas_call_id:
        return JsonResponse({"status": "ignored", "reason": "no call_id"})

    # Find or create guest by phone number
    guest = None
    if phone_number:
        guest, _ = Guest.objects.get_or_create(
            phone=phone_number,
            defaults={"source": Guest.Source.VOICE},
        )

    # Create or update call record
    call_record, created = CallRecord.objects.update_or_create(
        atlas_call_id=atlas_call_id,
        defaults={
            "guest": guest,
            "phone_number": phone_number,
            "direction": direction,
            "status": _map_call_status(call_status),
            "transcript": transcript,
            "outcome": _map_outcome(outcome),
            "duration_seconds": duration,
        },
    )

    # If Atlas detected a booking action, create booking with protection
    booking_data = payload.get("booking")
    if booking_data and guest:
        try:
            booking = create_booking_safe(
                guest=guest,
                date_value=booking_data.get("date"),
                time_start=booking_data.get("time_start", "18:00"),
                time_end=booking_data.get("time_end", "23:00"),
                source=Booking.Source.VOICE,
                notes=f"Booked via Atlas.AI call {atlas_call_id}",
            )
            call_record.booking = booking
            call_record.save(update_fields=["booking"])
            sync_booking_to_calcom(booking)
            logger.info("Booking created from Atlas call %s: %s", atlas_call_id, booking.id)

        except BookingError as exc:
            # Slot already booked - log but don't fail the webhook
            logger.warning(
                "Booking from Atlas call %s failed: %s (guest: %s)",
                atlas_call_id,
                exc,
                guest.phone,
            )

    action = "created" if created else "updated"
    logger.info("Atlas webhook: call %s %s (status=%s, outcome=%s)", atlas_call_id, action, call_status, outcome)

    return JsonResponse({"status": "ok", "action": action})


def _map_call_status(raw: str) -> str:
    """Map Atlas.AI status to our CallRecord.Status."""
    mapping = {
        "initiated": CallRecord.Status.INITIATED,
        "ringing": CallRecord.Status.INITIATED,
        "in_progress": CallRecord.Status.IN_PROGRESS,
        "answered": CallRecord.Status.IN_PROGRESS,
        "completed": CallRecord.Status.COMPLETED,
        "ended": CallRecord.Status.COMPLETED,
        "failed": CallRecord.Status.FAILED,
        "no_answer": CallRecord.Status.FAILED,
    }
    return mapping.get(raw.lower(), CallRecord.Status.INITIATED)


def _map_outcome(raw: str) -> str:
    """Map Atlas.AI outcome to our CallRecord.Outcome."""
    mapping = {
        "booked": CallRecord.Outcome.BOOKED,
        "booking": CallRecord.Outcome.BOOKED,
        "membership": CallRecord.Outcome.MEMBERSHIP_INQUIRY,
        "membership_inquiry": CallRecord.Outcome.MEMBERSHIP_INQUIRY,
        "waitlist": CallRecord.Outcome.WAITLIST,
        "general": CallRecord.Outcome.GENERAL,
    }
    return mapping.get(raw.lower(), CallRecord.Outcome.NO_ACTION)


@csrf_exempt
@require_POST
def check_availability_action(request: HttpRequest) -> JsonResponse:
    """
    Atlas Action endpoint: Check if a booking slot is available.
    
    This endpoint is called by Atlas AI during phone conversations
    to check slot availability in real-time.
    
    Request body:
    {
        "date": "2026-03-21",
        "time": "18:00"
    }
    
    Response:
    {
        "available": true,
        "message": "Slot is available for booking",
        "date": "2026-03-21",
        "time": "18:00"
    }
    """
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    date_str = data.get("date", "")
    time_str = data.get("time", "")

    if not date_str or not time_str:
        return JsonResponse(
            {
                "available": False,
                "message": "Missing date or time parameter",
            },
            status=400,
        )

    # Check availability
    result = check_slot_availability(date_str, time_str)

    return JsonResponse(
        {
            "available": result["available"],
            "message": result["reason"],
            "date": date_str,
            "time": time_str,
        }
    )

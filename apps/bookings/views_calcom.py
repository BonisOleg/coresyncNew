"""
Cal.com webhook handler.
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

from .models import Booking

logger = logging.getLogger(__name__)


@csrf_exempt
@require_POST
def calcom_webhook(request: HttpRequest) -> HttpResponse:
    """
    Handle Cal.com webhook events (booking.created, booking.cancelled, etc.).
    """
    # Verify webhook signature
    secret = settings.CALCOM_WEBHOOK_SECRET
    if secret:
        signature = request.headers.get("X-Cal-Signature-256", "")
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

    event_type = payload.get("triggerEvent", "")
    booking_uid = payload.get("payload", {}).get("uid", "")

    if not booking_uid:
        return JsonResponse({"status": "ignored"})

    try:
        booking = Booking.objects.get(calcom_booking_uid=booking_uid)
    except Booking.DoesNotExist:
        logger.warning("Cal.com webhook: booking uid=%s not found in DB.", booking_uid)
        return JsonResponse({"status": "not_found"})

    if event_type == "BOOKING_CANCELLED":
        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=["status"])
        logger.info("Booking %s cancelled via Cal.com.", booking.id)

    elif event_type == "BOOKING_RESCHEDULED":
        new_payload = payload.get("payload", {})
        booking.date = new_payload.get("startTime", booking.date)
        booking.save(update_fields=["date"])
        logger.info("Booking %s rescheduled via Cal.com.", booking.id)

    return JsonResponse({"status": "ok"})

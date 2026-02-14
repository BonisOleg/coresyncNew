"""
Concierge action handlers — execute parsed actions from Gemini responses.
Creates bookings, memberships, waitlist entries, and triggers Atlas.AI calls.
"""

from __future__ import annotations

import logging
from typing import Any

from apps.atlas_calls.utils import initiate_atlas_call
from apps.backyard.models import WaitlistEntry
from apps.bookings.models import Booking
from apps.bookings.services import BookingError, create_booking_safe
from apps.bookings.utils import sync_booking_to_calcom
from apps.concierge.models import ConciergeImage, Conversation
from apps.guests.models import Guest

logger = logging.getLogger(__name__)


def handle_book_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Handle a booking action from the concierge.
    Creates or finds a Guest, creates a Booking, and syncs to Cal.com.
    """
    metadata: dict[str, Any] = {"action_triggered": "book"}

    phone = action.get("phone", "")
    guest_name = action.get("guest_name", "")
    date_str = action.get("date", "")
    time_str = action.get("time", "18:00")

    if not phone or not date_str:
        metadata["action_status"] = "incomplete"
        metadata["missing_fields"] = []
        if not phone:
            metadata["missing_fields"].append("phone")
        if not date_str:
            metadata["missing_fields"].append("date")
        return metadata

    # Find or create guest
    guest, _ = Guest.objects.get_or_create(
        phone=phone,
        defaults={
            "first_name": guest_name.split(" ")[0] if guest_name else "",
            "last_name": " ".join(guest_name.split(" ")[1:]) if guest_name else "",
            "source": Guest.Source.WEB,
        },
    )

    # Link guest to conversation
    if not conversation.guest:
        conversation.guest = guest
        conversation.save(update_fields=["guest"])

    # Create booking with race condition protection
    try:
        booking = create_booking_safe(
            guest=guest,
            date_value=date_str,
            time_start=time_str,
            time_end="23:00",
            source=Booking.Source.WEB_CHAT,
            notes=f"Booked via concierge chat (session {conversation.session_id[:8]})",
        )

        # Sync to Cal.com
        sync_booking_to_calcom(booking)

        metadata["action_status"] = "success"
        metadata["booking_id"] = str(booking.id)
        logger.info("Booking created via concierge: %s for guest %s", booking.id, guest.phone)

    except BookingError as exc:
        # Slot is not available or already booked
        metadata["action_status"] = "failed"
        metadata["error"] = str(exc)
        logger.warning("Booking failed for %s: %s", guest.phone, exc)

    return metadata


def handle_membership_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Handle a membership inquiry action.
    Creates or finds a Guest and flags for follow-up.
    """
    metadata: dict[str, Any] = {"action_triggered": "membership"}

    phone = action.get("phone", "")
    email = action.get("email", "")
    guest_name = action.get("guest_name", "")

    if not phone and not email:
        metadata["action_status"] = "incomplete"
        return metadata

    if phone:
        guest, _ = Guest.objects.get_or_create(
            phone=phone,
            defaults={
                "email": email,
                "first_name": guest_name.split(" ")[0] if guest_name else "",
                "last_name": " ".join(guest_name.split(" ")[1:]) if guest_name else "",
                "source": Guest.Source.WEB,
            },
        )
        if email and not guest.email:
            guest.email = email
            guest.save(update_fields=["email"])

        if not conversation.guest:
            conversation.guest = guest
            conversation.save(update_fields=["guest"])

    metadata["action_status"] = "success"
    logger.info("Membership inquiry via concierge: %s", phone or email)
    return metadata


def handle_waitlist_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Handle a Backyard waitlist action.
    Creates a WaitlistEntry.
    """
    metadata: dict[str, Any] = {"action_triggered": "waitlist_backyard"}

    name = action.get("name", "")
    email = action.get("email", "")

    if not email and not name:
        metadata["action_status"] = "incomplete"
        return metadata

    entry = WaitlistEntry.objects.create(
        guest=conversation.guest,
        name=name,
        email=email,
        source=WaitlistEntry.Source.WEB_CHAT,
    )

    metadata["action_status"] = "success"
    metadata["waitlist_id"] = str(entry.id)
    logger.info("Backyard waitlist entry created: %s", entry.id)
    return metadata


def handle_show_images_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Handle a show images action — return Cloudinary image URLs.
    """
    metadata: dict[str, Any] = {"action_triggered": "show_images"}

    category = action.get("category", "suite")
    images = ConciergeImage.objects.filter(category=category)

    metadata["images"] = [
        {"title": img.title, "url": img.image.url if img.image else ""}
        for img in images
    ]
    metadata["action_status"] = "success"
    return metadata


def handle_transfer_to_voice(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Handle transfer to Atlas.AI voice call.
    """
    metadata: dict[str, Any] = {"action_triggered": "transfer_to_voice"}

    phone = action.get("phone", "")
    if not phone and conversation.guest:
        phone = conversation.guest.phone

    if not phone:
        metadata["action_status"] = "incomplete"
        metadata["missing_fields"] = ["phone"]
        return metadata

    # Build context for the voice agent
    context = {
        "conversation_id": str(conversation.id),
        "guest_name": conversation.guest.full_name if conversation.guest else "",
    }

    call_id = initiate_atlas_call(phone, context)

    if call_id:
        metadata["action_status"] = "success"
        metadata["atlas_call_id"] = call_id
    else:
        metadata["action_status"] = "failed"

    return metadata


def execute_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """
    Route an action to the appropriate handler.
    """
    action_type = action.get("action", "")

    handlers = {
        "book": handle_book_action,
        "membership": handle_membership_action,
        "waitlist_backyard": handle_waitlist_action,
        "show_images": handle_show_images_action,
        "transfer_to_voice": handle_transfer_to_voice,
    }

    handler = handlers.get(action_type)
    if handler:
        return handler(action, conversation)

    return {"action_triggered": action_type, "action_status": "unknown"}

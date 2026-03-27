"""
Booking flow — deterministic step-by-step handlers for the structured
booking conversation. Each handler returns the next UI to render.
"""

from __future__ import annotations

import logging
from datetime import date, timedelta
from typing import Any

from django.conf import settings
from django.utils import timezone

from apps.bookings.models import Booking, BookingSlot
from apps.bookings.services import BookingError, create_booking_safe
from apps.bookings.utils import sync_booking_to_calcom
from apps.concierge.models import Conversation
from apps.guests.models import Guest
from apps.spa_control.models import Scene

logger = logging.getLogger(__name__)

FULL_EXPERIENCE_PRICE = getattr(settings, "CORESYNC_FULL_PRICE", 350)
BASIC_EXPERIENCE_PRICE = getattr(settings, "CORESYNC_BASIC_PRICE", 250)


def handle_booking_step(
    conversation: Conversation,
    step: str,
    data: dict[str, Any],
) -> dict[str, Any]:
    """Route to the correct booking step handler."""
    handlers: dict[str, Any] = {
        "start_booking": _start_booking,
        "select_date": _select_date,
        "select_time": _select_time,
        "experience_tier": _experience_tier,
        "food_preference": _food_preference,
        "guest_name": _guest_name,
        "phone": _phone,
        "otp_verify": _otp_verify,
        "email": _email,
        "summary": _summary,
        "payment_confirm": _payment_confirm,
        "confirmation": _confirmation,
        "environment": _environment,
        "environment_confirm": _environment_confirm,
    }

    handler = handlers.get(step)
    if not handler:
        logger.warning("Unknown booking step: %s", step)
        return {
            "content": "I'm here to help. Would you like to book a session?",
            "message_type": "buttons",
            "flow": "booking",
            "next_step": "start_booking",
            "ui_data": {
                "buttons": [
                    {"label": "Book a session", "flow_step": "start_booking"},
                ]
            },
        }

    return handler(conversation, data)


def _start_booking(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 2: Show calendar picker for date selection."""
    today = date.today()
    max_date = today + timedelta(days=90)

    available_dates = list(
        BookingSlot.objects.filter(
            date__gte=today,
            date__lte=max_date,
            is_available=True,
        )
        .values_list("date", flat=True)
        .distinct()
        .order_by("date")
    )

    return {
        "content": "When would you like to visit?",
        "message_type": "calendar",
        "flow": "booking",
        "next_step": "select_date",
        "ui_data": {
            "min_date": today.isoformat(),
            "max_date": max_date.isoformat(),
            "available_dates": [d.isoformat() for d in available_dates],
        },
    }


def _select_date(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 3: Show available time slots for the chosen date."""
    selected_date = data.get("date", "")
    if not selected_date:
        return _start_booking(conversation, data)

    slots = BookingSlot.objects.filter(
        date=selected_date,
        is_available=True,
    ).order_by("time_start")

    available_slots = []
    for slot in slots:
        if slot.remaining_capacity > 0:
            available_slots.append(
                {
                    "time_start": slot.time_start.strftime("%H:%M"),
                    "time_end": slot.time_end.strftime("%H:%M"),
                    "display": slot.time_start.strftime("%-I:%M %p"),
                }
            )

    if not available_slots:
        return {
            "content": "There are no available times for that date. Would you like to try another day?",
            "message_type": "calendar",
            "flow": "booking",
            "next_step": "select_date",
            "ui_data": {
                "min_date": date.today().isoformat(),
                "max_date": (date.today() + timedelta(days=90)).isoformat(),
                "available_dates": list(
                    BookingSlot.objects.filter(
                        date__gte=date.today(),
                        is_available=True,
                    )
                    .values_list("date", flat=True)
                    .distinct()
                    .order_by("date")
                ),
            },
        }

    return {
        "content": "What time works best for you?",
        "message_type": "time_slots",
        "flow": "booking",
        "next_step": "select_time",
        "ui_data": {"slots": available_slots, "date": selected_date},
    }


def _select_time(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 3.5: Show experience tier selection."""
    if not data.get("time"):
        return _select_date(conversation, data)

    return {
        "content": "Your session includes the Full CoreSync Experience, prepared with food and refreshments.",
        "message_type": "experience_tier",
        "flow": "booking",
        "next_step": "experience_tier",
        "ui_data": {
            "tiers": [
                {
                    "id": "full",
                    "label": "Full Experience",
                    "price": FULL_EXPERIENCE_PRICE,
                    "highlighted": True,
                },
                {
                    "id": "basic",
                    "label": "Experience without food",
                    "price": BASIC_EXPERIENCE_PRICE,
                    "highlighted": False,
                },
            ],
            "note": "Members receive preferred pricing.",
        },
    }


def _experience_tier(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """If full experience chosen, ask food preference. Otherwise skip."""
    tier = data.get("experience_tier", "full")
    if tier == "full":
        return {
            "content": "Would you prefer dairy or meat for your visit?",
            "message_type": "buttons",
            "flow": "booking",
            "next_step": "food_preference",
            "ui_data": {
                "buttons": [
                    {"label": "Dairy", "value": "dairy", "flow_step": "food_preference", "field_name": "food_preference"},
                    {"label": "Meat", "value": "meat", "flow_step": "food_preference", "field_name": "food_preference"},
                ],
            },
        }
    return _guest_name(conversation, data)


def _food_preference(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 4: Ask for guest name."""
    return _guest_name(conversation, data)


def _guest_name(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 4: Collect first and last name."""
    return {
        "content": "What name should I reserve the session under?",
        "message_type": "input_fields",
        "flow": "booking",
        "next_step": "guest_name",
        "ui_data": {
            "fields": [
                {"name": "first_name", "label": "First Name", "type": "text", "required": True},
                {"name": "last_name", "label": "Last Name", "type": "text", "required": True},
            ],
            "submit_label": "Continue",
            "submit_flow_step": "phone",
        },
    }


def _phone(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 5: Collect phone number."""
    if not data.get("first_name"):
        return _guest_name(conversation, data)

    return {
        "content": "What phone number should I send your confirmation to?",
        "message_type": "input_fields",
        "flow": "booking",
        "next_step": "phone",
        "ui_data": {
            "fields": [
                {"name": "phone", "label": "Phone Number", "type": "tel", "required": True},
            ],
            "submit_label": "Send Code",
            "submit_flow_step": "otp_verify",
        },
    }


def _otp_verify(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 5 cont: Send OTP and ask for code, or verify submitted code."""
    phone = data.get("phone", "")
    otp = data.get("otp", "")

    if not phone:
        return _phone(conversation, data)

    guest, created = Guest.objects.get_or_create(
        phone=phone,
        defaults={
            "first_name": data.get("first_name", ""),
            "last_name": data.get("last_name", ""),
            "source": Guest.Source.WEB,
        },
    )

    if not conversation.guest:
        conversation.guest = guest
        conversation.save(update_fields=["guest"])

    if not otp:
        try:
            from .booking_sms import send_booking_otp
            send_booking_otp(guest)
        except ImportError:
            import random
            code = f"{random.randint(100000, 999999)}"
            guest.otp_code = code
            guest.otp_expires_at = timezone.now() + timedelta(minutes=10)
            guest.save(update_fields=["otp_code", "otp_expires_at"])
            logger.info("OTP for %s: %s (SMS not configured)", phone, code)

        return {
            "content": "Enter the 6-digit code I just sent.",
            "message_type": "input_fields",
            "flow": "booking",
            "next_step": "otp_verify",
            "ui_data": {
                "fields": [
                    {"name": "otp", "label": "Verification Code", "type": "text", "required": True, "maxlength": 6},
                ],
                "submit_label": "Verify",
                "submit_flow_step": "otp_verify",
            },
        }

    if not guest.is_otp_valid(otp):
        return {
            "content": "That code doesn't match. Please try again.",
            "message_type": "input_fields",
            "flow": "booking",
            "next_step": "otp_verify",
            "ui_data": {
                "fields": [
                    {"name": "otp", "label": "Verification Code", "type": "text", "required": True, "maxlength": 6},
                ],
                "submit_label": "Verify",
                "submit_flow_step": "otp_verify",
                "error": "Invalid code. Please check and try again.",
            },
        }

    guest.otp_code = ""
    guest.otp_expires_at = None
    if not guest.first_name and data.get("first_name"):
        guest.first_name = data["first_name"]
    if not guest.last_name and data.get("last_name"):
        guest.last_name = data["last_name"]
    guest.save(update_fields=["otp_code", "otp_expires_at", "first_name", "last_name"])

    has_previous = Booking.objects.filter(
        guest=guest, status__in=[Booking.Status.CONFIRMED, Booking.Status.COMPLETED]
    ).exists()

    if has_previous and not created:
        last_booking = (
            Booking.objects.filter(
                guest=guest, status__in=[Booking.Status.CONFIRMED, Booking.Status.COMPLETED]
            )
            .order_by("-date")
            .first()
        )
        ctx = conversation.context or {}
        ctx["returning_guest"] = True
        if last_booking:
            ctx["last_booking"] = {
                "experience_tier": last_booking.experience_tier,
                "food_preference": last_booking.food_preference,
            }
        conversation.context = ctx
        conversation.save(update_fields=["context"])

        return {
            "content": f"Welcome back, {guest.first_name}. Would you like to book the same experience as last time?",
            "message_type": "buttons",
            "flow": "booking",
            "next_step": "email",
            "ui_data": {
                "buttons": [
                    {"label": "Same time again", "flow_step": "email", "value": "same"},
                    {"label": "Choose new time", "flow_step": "start_booking", "value": "new"},
                ],
            },
            "metadata": {"returning_guest": True},
        }

    return _email_step(conversation, data)


def _email(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 6: Optional email."""
    return _email_step(conversation, data)


def _email_step(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 6: Ask for optional email."""
    return {
        "content": "Would you like your confirmation and receipt sent to an email as well?",
        "message_type": "input_fields",
        "flow": "booking",
        "next_step": "email",
        "ui_data": {
            "fields": [
                {"name": "email", "label": "Email Address", "type": "email", "required": False},
            ],
            "submit_label": "Add Email",
            "submit_flow_step": "summary",
            "skip_label": "Skip",
            "skip_flow_step": "summary",
        },
    }


def _calculate_duration(time_start: str, time_end: str) -> str:
    """Calculate human-readable duration between two HH:MM times."""
    from datetime import datetime

    t1 = datetime.strptime(time_start, "%H:%M")
    t2 = datetime.strptime(time_end, "%H:%M")
    diff = t2 - t1
    if diff.total_seconds() < 0:
        diff += timedelta(days=1)
    hours = diff.total_seconds() / 3600
    if hours == int(hours):
        h = int(hours)
        return f"{h} {'hour' if h == 1 else 'hours'}"
    return f"{hours:.1f} hours"


def _summary(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 7: Show booking summary with terms and payment."""
    tier = data.get("experience_tier", "full")
    price = FULL_EXPERIENCE_PRICE if tier == "full" else BASIC_EXPERIENCE_PRICE

    if data.get("email") and conversation.guest:
        guest = conversation.guest
        if not guest.email:
            guest.email = data["email"]
            guest.save(update_fields=["email"])

    time_start = data.get("time", "18:00")
    duration = _calculate_duration(time_start, "23:00")

    return {
        "content": "You're reserving CoreSync Private for:",
        "message_type": "summary",
        "flow": "booking",
        "next_step": "summary",
        "ui_data": {
            "date": data.get("date", ""),
            "time": time_start,
            "duration": duration,
            "experience_tier": "Full Experience" if tier == "full" else "Experience without food",
            "food_preference": data.get("food_preference", ""),
            "price": price,
            "currency": "USD",
            "terms_url": "/terms/",
            "cancellation_url": "/cancellation-policy/",
            "submit_flow_step": "payment_confirm",
        },
    }


def _payment_confirm(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 7 cont: Process payment and create booking."""
    if not data.get("terms_accepted"):
        summary_result = _summary(conversation, data)
        return {
            **summary_result,
            "ui_data": {
                **summary_result["ui_data"],
                "error": "Please agree to the Terms & Conditions to continue.",
            },
        }

    guest = conversation.guest
    if not guest:
        logger.error("No guest linked to conversation %s at payment step", conversation.id)
        return _phone(conversation, data)

    tier = data.get("experience_tier", "full")
    price = FULL_EXPERIENCE_PRICE if tier == "full" else BASIC_EXPERIENCE_PRICE

    try:
        booking = create_booking_safe(
            guest=guest,
            date_value=data.get("date", ""),
            time_start=data.get("time", "18:00"),
            time_end="23:00",
            source=Booking.Source.WEB_CHAT,
            notes=f"Booked via concierge flow (session {conversation.session_id[:8]})",
        )
    except BookingError as exc:
        logger.warning("Booking creation failed: %s", exc)
        return {
            "content": f"I'm sorry, that slot is no longer available. {exc}",
            "message_type": "calendar",
            "flow": "booking",
            "next_step": "select_date",
            "ui_data": {
                "min_date": date.today().isoformat(),
                "max_date": (date.today() + timedelta(days=90)).isoformat(),
                "available_dates": list(
                    BookingSlot.objects.filter(date__gte=date.today(), is_available=True)
                    .values_list("date", flat=True)
                    .distinct()
                    .order_by("date")
                ),
                "error": str(exc),
            },
        }

    booking.experience_tier = tier
    booking.food_preference = data.get("food_preference", "")
    booking.terms_accepted_at = timezone.now()

    try:
        from apps.concierge.stripe_utils import create_booking_payment_intent

        pi = create_booking_payment_intent(guest, price, str(booking.id))
        booking.stripe_payment_intent_id = pi["id"]
        booking.save(
            update_fields=[
                "experience_tier", "food_preference", "terms_accepted_at",
                "stripe_payment_intent_id",
            ]
        )

        return {
            "content": "Complete your payment to confirm the booking.",
            "message_type": "payment",
            "flow": "booking",
            "next_step": "confirmation",
            "ui_data": {
                "client_secret": pi["client_secret"],
                "amount": price,
                "currency": "USD",
                "booking_id": str(booking.id),
                "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
            },
            "metadata": {"booking_id": str(booking.id)},
        }
    except Exception as exc:
        logger.warning("Stripe payment intent failed, proceeding without payment: %s", exc)
        booking.payment_status = Booking.PaymentStatus.UNPAID
        booking.status = Booking.Status.CONFIRMED
        booking.generate_confirmation_number()
        booking.save(
            update_fields=[
                "experience_tier", "food_preference", "terms_accepted_at",
                "payment_status", "status", "confirmation_number",
            ]
        )
        sync_booking_to_calcom(booking)
        return _build_confirmation(conversation, data, booking)


def _confirmation(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 8: Show booking confirmation after payment success."""
    guest = conversation.guest
    if not guest:
        return _phone(conversation, data)

    booking_id = data.get("booking_id") or (
        conversation.context or {}
    ).get("data", {}).get("booking_id")

    booking = None
    if booking_id:
        booking = Booking.objects.filter(id=booking_id, guest=guest).first()

    if not booking:
        booking = (
            Booking.objects.filter(guest=guest)
            .order_by("-created_at")
            .first()
        )

    if not booking:
        return _start_booking(conversation, data)

    if not booking.confirmation_number:
        booking.generate_confirmation_number()

    if booking.payment_status != Booking.PaymentStatus.PAID:
        if booking.stripe_payment_intent_id:
            from apps.concierge.stripe_utils import confirm_booking_payment

            if not confirm_booking_payment(booking.stripe_payment_intent_id):
                return {
                    "content": "Payment could not be verified. Please try again or contact support.",
                    "message_type": "payment",
                    "flow": "booking",
                    "next_step": "confirmation",
                    "ui_data": {
                        "error": "Payment verification failed.",
                        "booking_id": str(booking.id),
                    },
                }

        booking.payment_status = Booking.PaymentStatus.PAID
        booking.status = Booking.Status.CONFIRMED
        booking.save(update_fields=["payment_status", "status"])

    sync_booking_to_calcom(booking)

    ctx = conversation.context or {}
    ctx.setdefault("data", {})["booking_id"] = str(booking.id)
    conversation.context = ctx
    conversation.save(update_fields=["context"])

    return _build_confirmation(conversation, data, booking)


def _build_confirmation(
    conversation: Conversation,
    data: dict[str, Any],
    booking: Booking,
) -> dict[str, Any]:
    """Build the confirmation response dict and send SMS/email (once)."""
    ctx = conversation.context or {}
    already_notified = ctx.get("confirmation_sent_for") == str(booking.id)

    if not already_notified:
        from apps.concierge.email import send_booking_confirmation_email
        from apps.concierge.sms import send_booking_confirmation

        guest = booking.guest

        if guest and guest.phone:
            send_booking_confirmation(guest, booking)
        if guest and guest.email:
            send_booking_confirmation_email(guest, booking)

        ctx["confirmation_sent_for"] = str(booking.id)
        conversation.context = ctx
        conversation.save(update_fields=["context"])

    whatsapp_number = getattr(settings, "WHATSAPP_NUMBER", "")
    whatsapp_url = ""
    if whatsapp_number:
        whatsapp_url = f"https://wa.me/{whatsapp_number}?text=Booking%20{booking.confirmation_number}"

    site_url = getattr(settings, "SITE_URL", "https://coresync.com")
    calendar_url = f"{site_url}/concierge/calendar/{booking.id}/"

    return {
        "content": "Your session is confirmed.",
        "message_type": "confirmation",
        "flow": "booking",
        "next_step": "environment",
        "ui_data": {
            "confirmation_number": booking.confirmation_number,
            "date": booking.date.isoformat(),
            "time": booking.time_start.strftime("%-I:%M %p"),
            "experience_tier": booking.get_experience_tier_display(),
            "booking_id": str(booking.id),
            "whatsapp_url": whatsapp_url,
            "calendar_url": calendar_url,
        },
        "metadata": {
            "action_triggered": "booking_confirmed",
            "booking_id": str(booking.id),
        },
    }


def _environment(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 8.5: Environment/scene selection."""
    scenes = Scene.objects.filter(is_active=True).order_by("order")

    scene_list = [
        {
            "id": str(s.id),
            "name": s.name,
            "description": s.description,
            "thumbnail_url": s.thumbnail_url,
        }
        for s in scenes
    ]

    return {
        "content": "Would you like to select the environment for your visit?",
        "message_type": "environment",
        "flow": "booking",
        "next_step": "environment_confirm",
        "ui_data": {"scenes": scene_list},
    }


def _environment_confirm(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Step 8.5 cont: Confirm scene selection."""
    scene_id = data.get("scene_id")
    booking_id = data.get("booking_id")

    scene_name = "your default"
    if scene_id and booking_id:
        try:
            scene = Scene.objects.get(id=scene_id)
            booking = Booking.objects.get(id=booking_id)
            booking.scene = scene
            booking.save(update_fields=["scene"])
            scene_name = scene.name
        except (Scene.DoesNotExist, Booking.DoesNotExist):
            pass

    from .membership import _membership_upsell_after_booking
    upsell = _membership_upsell_after_booking(conversation, data)
    if upsell:
        upsell["content"] = (
            f"Perfect. Your environment is set to {scene_name}. "
            "You can change it anytime before your visit.\n\n"
            + upsell["content"]
        )
        return upsell

    return {
        "content": (
            f"Perfect. Your environment is set to {scene_name}. "
            "You can change it anytime before your visit."
        ),
        "message_type": "text",
        "flow": None,
        "next_step": "",
        "metadata": {"flow_complete": True},
    }

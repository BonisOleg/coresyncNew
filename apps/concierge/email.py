"""
Email confirmation and .ics calendar file generation for bookings.
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import TYPE_CHECKING

from django.conf import settings
from django.core.mail import EmailMultiAlternatives

if TYPE_CHECKING:
    from apps.bookings.models import Booking
    from apps.guests.models import Guest

logger = logging.getLogger(__name__)


def generate_ics(booking: Booking) -> bytes:
    """Generate an .ics calendar file for the booking."""
    from icalendar import Calendar, Event, vText

    cal = Calendar()
    cal.add("prodid", "-//CoreSync Private//EN")
    cal.add("version", "2.0")
    cal.add("method", "REQUEST")

    event = Event()
    event.add("summary", "CoreSync Private Session")
    event.add("dtstart", datetime.combine(booking.date, booking.time_start))
    event.add("dtend", datetime.combine(booking.date, booking.time_end))
    event.add("uid", f"{booking.id}@coresync.com")

    description = (
        f"Confirmation: {booking.confirmation_number}\n"
        f"Experience: {booking.get_experience_tier_display()}"
    )
    if booking.food_preference:
        description += f"\nPreference: {booking.get_food_preference_display()}"
    event.add("description", description)

    event.add("location", vText("CoreSync Private"))
    event.add("status", "CONFIRMED")

    guest = booking.guest
    if guest and guest.full_name:
        from icalendar import vCalAddress

        attendee = vCalAddress(f"MAILTO:{guest.email}" if guest.email else "MAILTO:guest@coresync.com")
        attendee.params["cn"] = vText(guest.full_name)
        attendee.params["RSVP"] = "TRUE"
        event.add("attendee", attendee, encode=0)

    cal.add_component(event)
    return cal.to_ical()


def send_booking_confirmation_email(guest: Guest, booking: Booking) -> bool:
    """
    Send booking confirmation email with receipt and .ics attachment.
    Returns True on success.
    """
    if not guest.email:
        logger.info("No email for guest %s — skipping confirmation email", guest.id)
        return False

    date_str = booking.date.strftime("%B %d, %Y")
    time_str = booking.time_start.strftime("%-I:%M %p")
    tier = booking.get_experience_tier_display()

    subject = f"CoreSync Private — Booking Confirmed ({booking.confirmation_number})"

    text_body = (
        f"Your CoreSync Private session is confirmed.\n\n"
        f"Date: {date_str}\n"
        f"Time: {time_str}\n"
        f"Experience: {tier}\n"
        f"Confirmation: {booking.confirmation_number}\n\n"
        f"We look forward to welcoming you.\n"
        f"— CoreSync Private"
    )

    html_body = f"""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                max-width: 520px; margin: 0 auto; padding: 40px 24px;
                background: #0a0a0a; color: #e0e0e0;">
        <h2 style="font-weight: 300; letter-spacing: 0.05em; color: #c9a96e;
                   margin-bottom: 32px;">Session Confirmed</h2>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
            <tr>
                <td style="padding: 12px 0; color: #999; border-bottom: 1px solid #222;">Date</td>
                <td style="padding: 12px 0; text-align: right; border-bottom: 1px solid #222;">{date_str}</td>
            </tr>
            <tr>
                <td style="padding: 12px 0; color: #999; border-bottom: 1px solid #222;">Time</td>
                <td style="padding: 12px 0; text-align: right; border-bottom: 1px solid #222;">{time_str}</td>
            </tr>
            <tr>
                <td style="padding: 12px 0; color: #999; border-bottom: 1px solid #222;">Experience</td>
                <td style="padding: 12px 0; text-align: right; border-bottom: 1px solid #222;">{tier}</td>
            </tr>
            <tr>
                <td style="padding: 12px 0; color: #999;">Confirmation</td>
                <td style="padding: 12px 0; text-align: right; font-weight: 500;
                           letter-spacing: 0.1em; color: #c9a96e;">{booking.confirmation_number}</td>
            </tr>
        </table>
        <p style="font-size: 14px; color: #666; line-height: 1.6;">
            A calendar invitation is attached. We look forward to welcoming you.
        </p>
        <p style="margin-top: 32px; font-size: 12px; color: #444;
                  letter-spacing: 0.1em; text-transform: uppercase;">
            CoreSync Private
        </p>
    </div>
    """

    from_email = settings.DEFAULT_FROM_EMAIL

    try:
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_body,
            from_email=from_email,
            to=[guest.email],
        )
        email.attach_alternative(html_body, "text/html")

        ics_data = generate_ics(booking)
        email.attach("coresync-booking.ics", ics_data, "text/calendar")

        email.send(fail_silently=False)
        logger.info("Confirmation email sent to %s for booking %s", guest.email, booking.id)
        return True

    except Exception as exc:
        logger.error("Failed to send confirmation email to %s: %s", guest.email, exc)
        return False

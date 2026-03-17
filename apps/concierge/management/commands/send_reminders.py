"""
Management command to send pre-session SMS reminders.
Run via cron every 30 minutes:
  */30 * * * * python manage.py send_reminders
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.bookings.models import Booking
from apps.concierge.sms import send_pre_session_reminder

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Send SMS reminders for sessions starting in the next 1-2 hours."

    def handle(self, *args, **options):
        now = timezone.now()
        window_start = now + timedelta(hours=1)
        window_end = now + timedelta(hours=2)

        bookings = Booking.objects.filter(
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
            date=now.date(),
        ).select_related("guest")

        sent = 0
        for booking in bookings:
            session_start = timezone.make_aware(
                datetime.combine(booking.date, booking.time_start)
            )
            if window_start <= session_start <= window_end:
                if booking.preferences.get("reminder_sent"):
                    continue

                send_pre_session_reminder(booking.guest, booking)

                booking.preferences["reminder_sent"] = True
                booking.save(update_fields=["preferences"])
                sent += 1

        self.stdout.write(f"Sent {sent} reminder(s).")

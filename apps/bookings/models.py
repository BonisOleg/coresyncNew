"""
Booking management, available time slots, and check-in tracking.
"""

from __future__ import annotations

import random
import string
import uuid
from datetime import datetime, timedelta

from django.db import models
from django.utils import timezone


class BookingSlot(models.Model):
    """Available time slot for booking an evening."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(db_index=True)
    time_start = models.TimeField()
    time_end = models.TimeField()
    is_available = models.BooleanField(default=True)
    max_capacity = models.PositiveIntegerField(default=1)

    class Meta:
        ordering = ["date", "time_start"]
        unique_together = [("date", "time_start", "time_end")]

    def __str__(self) -> str:
        avail = "Available" if self.is_available else "Unavailable"
        return f"{self.date} {self.time_start}–{self.time_end} ({avail})"

    @property
    def current_bookings_count(self) -> int:
        return self.bookings.filter(
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        ).count()

    @property
    def remaining_capacity(self) -> int:
        return max(0, self.max_capacity - self.current_bookings_count)


class Booking(models.Model):
    """A guest's booking for a private evening."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        CANCELLED = "cancelled", "Cancelled"
        COMPLETED = "completed", "Completed"

    class Source(models.TextChoices):
        WEB_CHAT = "web_chat", "Web Chat"
        VOICE = "voice", "Voice Call"
        FLUTTER = "flutter", "Flutter App"
        ADMIN = "admin", "Admin"

    class ExperienceTier(models.TextChoices):
        FULL = "full", "Full Experience"
        BASIC = "basic", "Without Food"

    class FoodPreference(models.TextChoices):
        DAIRY = "dairy", "Dairy"
        MEAT = "meat", "Meat"

    class PaymentStatus(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PAID = "paid", "Paid"
        REFUNDED = "refunded", "Refunded"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        "guests.Guest",
        on_delete=models.CASCADE,
        related_name="bookings",
    )
    slot = models.ForeignKey(
        BookingSlot,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="bookings",
    )
    date = models.DateField(db_index=True)
    time_start = models.TimeField()
    time_end = models.TimeField()

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )

    experience_tier = models.CharField(
        max_length=20,
        choices=ExperienceTier.choices,
        default=ExperienceTier.FULL,
    )
    food_preference = models.CharField(
        max_length=20,
        choices=FoodPreference.choices,
        blank=True,
        default="",
    )
    payment_status = models.CharField(
        max_length=20,
        choices=PaymentStatus.choices,
        default=PaymentStatus.UNPAID,
    )
    stripe_payment_intent_id = models.CharField(max_length=255, blank=True, default="")
    confirmation_number = models.CharField(max_length=20, unique=True, blank=True, default="")
    scene = models.ForeignKey(
        "spa_control.Scene",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="bookings",
    )
    terms_accepted_at = models.DateTimeField(null=True, blank=True)

    preferences = models.JSONField(default=dict, blank=True)

    calcom_event_id = models.CharField(max_length=255, blank=True, default="")
    calcom_booking_uid = models.CharField(max_length=255, blank=True, default="")

    source = models.CharField(
        max_length=20,
        choices=Source.choices,
        default=Source.WEB_CHAT,
    )

    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-date", "-time_start"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.date} {self.time_start} ({self.status})"

    @property
    def session_end_datetime(self) -> datetime:
        return timezone.make_aware(
            datetime.combine(self.date, self.time_end),
        )

    @property
    def session_start_datetime(self) -> datetime:
        return timezone.make_aware(
            datetime.combine(self.date, self.time_start),
        )

    @property
    def total_seconds(self) -> int:
        delta = self.session_end_datetime - self.session_start_datetime
        return max(0, int(delta.total_seconds()))

    def generate_confirmation_number(self) -> str:
        """Generate and save a unique human-readable confirmation number."""
        for _ in range(10):
            code = "CS-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
            if not Booking.objects.filter(confirmation_number=code).exists():
                self.confirmation_number = code
                self.save(update_fields=["confirmation_number"])
                return code
        raise RuntimeError("Could not generate unique confirmation number")


class CheckIn(models.Model):
    """Tracks guest check-in / check-out for a booking."""

    class Status(models.TextChoices):
        CHECKED_IN = "checked_in", "Checked In"
        CHECKED_OUT = "checked_out", "Checked Out"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name="checkin")
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="checkins")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.CHECKED_IN)
    checked_in_at = models.DateTimeField(auto_now_add=True)
    checked_out_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-checked_in_at"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.booking.date} ({self.status})"

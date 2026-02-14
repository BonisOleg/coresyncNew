"""
Booking management and available time slots.
"""

from __future__ import annotations

import uuid

from django.db import models


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
        status = "Available" if self.is_available else "Unavailable"
        return f"{self.date} {self.time_start}–{self.time_end} ({status})"


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

    # Guest preferences for this specific booking (JSON)
    preferences = models.JSONField(default=dict, blank=True)

    # Cal.com sync references
    calcom_event_id = models.CharField(max_length=255, blank=True, default="")
    calcom_booking_uid = models.CharField(max_length=255, blank=True, default="")

    # Where the booking originated
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

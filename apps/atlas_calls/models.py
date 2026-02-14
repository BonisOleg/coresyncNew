"""
Atlas.AI voice call records and webhook data.
"""

from __future__ import annotations

import uuid

from django.db import models


class CallRecord(models.Model):
    """Record of a voice call handled by Atlas.AI."""

    class Direction(models.TextChoices):
        INBOUND = "inbound", "Inbound"
        OUTBOUND = "outbound", "Outbound"

    class Status(models.TextChoices):
        INITIATED = "initiated", "Initiated"
        IN_PROGRESS = "in_progress", "In Progress"
        COMPLETED = "completed", "Completed"
        FAILED = "failed", "Failed"

    class Outcome(models.TextChoices):
        BOOKED = "booked", "Booked"
        MEMBERSHIP_INQUIRY = "membership_inquiry", "Membership Inquiry"
        WAITLIST = "waitlist", "Waitlist"
        GENERAL = "general", "General Inquiry"
        NO_ACTION = "no_action", "No Action"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        "guests.Guest",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="call_records",
    )
    atlas_call_id = models.CharField(
        max_length=255,
        unique=True,
        db_index=True,
        help_text="Call ID from Atlas.AI platform.",
    )
    phone_number = models.CharField(max_length=20, db_index=True)
    direction = models.CharField(
        max_length=20,
        choices=Direction.choices,
        default=Direction.OUTBOUND,
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.INITIATED,
    )
    transcript = models.TextField(blank=True, default="")
    outcome = models.CharField(
        max_length=30,
        choices=Outcome.choices,
        default=Outcome.NO_ACTION,
    )
    duration_seconds = models.PositiveIntegerField(default=0)
    booking = models.ForeignKey(
        "bookings.Booking",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="call_records",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Call {self.atlas_call_id[:8]} — {self.phone_number} ({self.status})"

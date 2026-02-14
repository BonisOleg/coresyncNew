"""
Guest profiles, membership definitions, and guest-membership relationships.
"""

from __future__ import annotations

import uuid
from typing import Any

from django.db import models
from django.utils import timezone


class Membership(models.Model):
    """A membership tier (e.g. Evening, Monthly, Annual)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Guest(models.Model):
    """
    Central guest profile shared across web chat, voice calls, and Flutter.
    Unregistered guests store minimal info; registered guests have full profile.
    """

    class Source(models.TextChoices):
        WEB = "web", "Web Chat"
        VOICE = "voice", "Voice Call"
        FLUTTER = "flutter", "Flutter App"
        WHATSAPP = "whatsapp", "WhatsApp"
        ADMIN = "admin", "Admin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=20, unique=True, db_index=True)
    email = models.EmailField(blank=True, default="")
    first_name = models.CharField(max_length=100, blank=True, default="")
    last_name = models.CharField(max_length=100, blank=True, default="")

    is_registered = models.BooleanField(
        default=False,
        help_text="True after the guest completes full registration.",
    )

    # Preferences for SPA experience (light, temperature, music, etc.)
    preferences: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    # Face ID / biometric token for Flutter app device binding
    face_id_token = models.CharField(max_length=512, blank=True, default="")

    # Internal notes (from concierge / admin)
    notes = models.TextField(blank=True, default="")

    # Where this guest first appeared
    source = models.CharField(
        max_length=20,
        choices=Source.choices,
        default=Source.WEB,
    )

    # OTP for phone-based authentication
    otp_code = models.CharField(max_length=6, blank=True, default="")
    otp_expires_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        name = f"{self.first_name} {self.last_name}".strip()
        return name or self.phone

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}".strip()

    def is_otp_valid(self, code: str) -> bool:
        """Check if OTP code matches and is not expired."""
        if not self.otp_code or not self.otp_expires_at:
            return False
        return self.otp_code == code and timezone.now() < self.otp_expires_at


class GuestMembership(models.Model):
    """Links a guest to a membership tier with status and dates."""

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        PAUSED = "paused", "Paused"
        EXPIRED = "expired", "Expired"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        Guest,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    membership = models.ForeignKey(
        Membership,
        on_delete=models.PROTECT,
        related_name="guest_memberships",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
    )
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)

    # Stripe subscription ID (prepared for future payments)
    stripe_subscription_id = models.CharField(max_length=255, blank=True, default="")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-start_date"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.membership} ({self.status})"

    def is_active_now(self) -> bool:
        """Check if membership is currently active."""
        if self.status != self.Status.ACTIVE:
            return False
        today = timezone.now().date()
        if self.end_date and today > self.end_date:
            return False
        return today >= self.start_date

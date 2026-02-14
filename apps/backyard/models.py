"""
Backyard waitlist / early access entries.
"""

from __future__ import annotations

import uuid

from django.db import models


class WaitlistEntry(models.Model):
    """Early access sign-up for the Backyard experience."""

    class Source(models.TextChoices):
        WEB_CHAT = "web_chat", "Web Chat"
        VOICE = "voice", "Voice Call"
        FLUTTER = "flutter", "Flutter App"
        ADMIN = "admin", "Admin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        "guests.Guest",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="waitlist_entries",
    )
    email = models.EmailField(blank=True, default="")
    phone = models.CharField(max_length=20, blank=True, default="")
    name = models.CharField(max_length=200, blank=True, default="")
    source = models.CharField(
        max_length=20,
        choices=Source.choices,
        default=Source.WEB_CHAT,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name_plural = "Waitlist entries"

    def __str__(self) -> str:
        return self.name or self.email or self.phone or "Anonymous"

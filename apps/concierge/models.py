"""
AI concierge conversation history and managed images.
"""

from __future__ import annotations

import uuid
from typing import Any

from django.db import models


class Conversation(models.Model):
    """A chat session between a guest and the AI concierge."""

    class Channel(models.TextChoices):
        WEB = "web", "Web Chat"
        FLUTTER = "flutter", "Flutter App"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        CLOSED = "closed", "Closed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        "guests.Guest",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="conversations",
    )
    channel = models.CharField(
        max_length=20,
        choices=Channel.choices,
        default=Channel.WEB,
    )
    session_id = models.CharField(
        max_length=255,
        unique=True,
        db_index=True,
        help_text="Browser session or device session identifier.",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ACTIVE,
    )
    # Tracks current conversational flow context
    context: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self) -> str:
        guest_label = str(self.guest) if self.guest else "Anonymous"
        return f"Conversation {self.session_id[:8]} — {guest_label}"


class Message(models.Model):
    """A single message in a conversation."""

    class Role(models.TextChoices):
        SYSTEM = "system", "System"
        ASSISTANT = "assistant", "Assistant"
        USER = "user", "User"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    role = models.CharField(max_length=20, choices=Role.choices)
    content = models.TextField()
    # Extra data: buttons shown, images revealed, actions triggered
    metadata: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self) -> str:
        preview = self.content[:60] + "…" if len(self.content) > 60 else self.content
        return f"[{self.role}] {preview}"


class ConciergeImage(models.Model):
    """Images that the concierge can reveal to guests during chat."""

    class Category(models.TextChoices):
        SUITE = "suite", "Suite"
        BACKYARD = "backyard", "Backyard"
        EXPERIENCE = "experience", "Experience"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    image = models.ImageField(upload_to="concierge_images/")
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.SUITE,
    )
    show_after_intent = models.BooleanField(
        default=True,
        help_text="Only show after guest demonstrates interest.",
    )
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["category", "order"]

    def __str__(self) -> str:
        return f"{self.title} ({self.category})"

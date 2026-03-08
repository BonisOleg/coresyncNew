"""Concierge utility functions."""

from __future__ import annotations

from datetime import timedelta

from django.utils import timezone


def is_rate_limited(session_id: str, max_per_minute: int = 6) -> bool:
    """
    Returns True if the session has sent too many messages in the last minute.
    Uses the existing Message table — no Redis or extra dependencies needed.
    """
    from .models import Message

    since = timezone.now() - timedelta(minutes=1)
    count = Message.objects.filter(
        conversation__session_id=session_id,
        role=Message.Role.USER,
        created_at__gte=since,
    ).count()
    return count >= max_per_minute

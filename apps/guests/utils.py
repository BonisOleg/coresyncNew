"""Utility functions for the guests app."""

from __future__ import annotations

from typing import TYPE_CHECKING

from .models import Guest

if TYPE_CHECKING:
    from rest_framework.request import Request


def get_guest_from_token(request: Request) -> Guest | None:
    """
    Extract the guest from the JWT token claims.
    Returns None if the guest cannot be found.
    """
    token = getattr(request, "auth", None)
    if token is None:
        return None

    guest_id = token.get("guest_id")
    if not guest_id:
        return None

    try:
        return Guest.objects.get(id=guest_id)
    except Guest.DoesNotExist:
        return None

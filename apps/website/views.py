"""
Website views — single room template and HTMX partials.
"""

from __future__ import annotations

import uuid

from django.conf import settings
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.shortcuts import render


def room_view(request: HttpRequest) -> HttpResponse:
    """Render the single immersive room — the entire website."""
    # Generate a session ID for the concierge conversation
    if "concierge_session" not in request.session:
        request.session["concierge_session"] = str(uuid.uuid4())

    context = {
        "session_id": request.session["concierge_session"],
        "whatsapp_number": settings.WHATSAPP_NUMBER,
    }
    return render(request, "website/room.html", context)


# ---------------------------------------------------------------------------
# Explore panel HTMX partials
# ---------------------------------------------------------------------------


def explore_panel(request: HttpRequest) -> HttpResponse:
    """Render the explore navigation panel."""
    return render(request, "website/partials/explore_panel.html")


def explore_experience(request: HttpRequest) -> HttpResponse:
    """The Experience section."""
    return render(request, "website/partials/experience.html")


def explore_membership(request: HttpRequest) -> HttpResponse:
    """Membership section."""
    return render(request, "website/partials/membership.html")


def explore_backyard(request: HttpRequest) -> HttpResponse:
    """The Backyard (Coming Soon) section."""
    return render(request, "website/partials/backyard.html")


def explore_story(request: HttpRequest) -> HttpResponse:
    """Brand story section."""
    return render(request, "website/partials/story.html")


def explore_contact(request: HttpRequest) -> HttpResponse:
    """Contact section."""
    context = {
        "whatsapp_number": settings.WHATSAPP_NUMBER,
    }
    return render(request, "website/partials/contact.html", context)


# ---------------------------------------------------------------------------
# Healthcheck
# ---------------------------------------------------------------------------


def healthcheck(request: HttpRequest) -> JsonResponse:
    """Simple healthcheck endpoint for Render."""
    return JsonResponse({"status": "ok"})

"""
Concierge HTMX views — web chat interface.
"""

from __future__ import annotations

import json
import logging
import uuid

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_GET, require_POST

from .engine import process_message
from .flow_engine import TEMPLATE_MAP, process_flow_message
from .models import Conversation, Message
from .utils import is_rate_limited

logger = logging.getLogger(__name__)

FLOW_DATA_KEYS = (
    "date", "time", "first_name", "last_name", "phone", "otp", "email",
    "experience_tier", "food_preference", "terms_accepted", "scene_id",
    "booking_id",
)


def concierge_panel(request: HttpRequest) -> HttpResponse:
    """Render the concierge chat panel (HTMX partial)."""
    session_id = request.session.get("concierge_session", str(uuid.uuid4()))
    request.session["concierge_session"] = session_id
    context_param = request.GET.get("context")

    conversation, created = Conversation.objects.get_or_create(
        session_id=session_id,
        defaults={"channel": Conversation.Channel.WEB},
    )

    separator_id = None
    if created or context_param == "explore_booking":
        content = (
            "Welcome to CoreSync Private.\n"
            "I'm your concierge. How can I assist you today?"
        )
        buttons = [
            {"label": "Book a session", "action": "book", "flow_step": "start_booking"},
            {"label": "Explore membership", "action": "membership", "flow_step": "start_membership"},
            {"label": "Just exploring", "action": "explore"},
        ]

        if context_param == "explore_booking":
            content = (
                "Welcome. I'm here to help you explore CoreSync Private, "
                "book your visit, or just feel the space. "
                "What would you like to start with?"
            )
            buttons = [
                {"label": "Book a session", "action": "book", "flow_step": "start_booking"},
                {"label": "Explore the space", "action": "explore"},
                {"label": "Explore membership", "action": "membership", "flow_step": "start_membership"},
            ]

        msg = Message.objects.create(
            conversation=conversation,
            role=Message.Role.ASSISTANT,
            content=content,
            metadata={"buttons": buttons},
        )
        separator_id = msg.id

    messages = conversation.messages.all()

    if separator_id is None and messages.exists():
        separator_id = messages.last().id

    context = {
        "conversation": conversation,
        "messages": messages,
        "session_id": session_id,
        "separator_id": separator_id,
    }
    return render(request, "website/partials/concierge_panel.html", context)


@require_POST
def concierge_message(request: HttpRequest) -> HttpResponse:
    """
    Handle a user message via HTMX.
    Routes to flow engine (structured steps) or Gemini (free-form).
    """
    session_id = request.session.get("concierge_session", str(uuid.uuid4()))
    user_message = request.POST.get("message", "").strip()
    action = request.POST.get("action", "")
    flow_step = request.POST.get("flow_step", "").strip()

    if not user_message and not action and not flow_step:
        return HttpResponse("")

    conversation, _ = Conversation.objects.get_or_create(
        session_id=session_id,
        defaults={"channel": Conversation.Channel.WEB},
    )

    effective_message = user_message or action or flow_step

    user_msg = Message.objects.create(
        conversation=conversation,
        role=Message.Role.USER,
        content=effective_message,
        metadata={"action": action, "flow_step": flow_step} if (action or flow_step) else {},
    )

    if is_rate_limited(session_id):
        throttle_msg = Message.objects.create(
            conversation=conversation,
            role=Message.Role.ASSISTANT,
            content="Just a moment — give me a breath before we continue.",
            metadata={"rate_limited": True},
        )
        return render(request, "website/partials/chat_message.html", {
            "user_message": user_msg,
            "assistant_message": throttle_msg,
            "metadata": {"rate_limited": True},
        })

    # --- Routing: flow engine vs Gemini ---
    if flow_step:
        flow_data: dict[str, str] = {}
        for key in FLOW_DATA_KEYS:
            val = request.POST.get(key, "")
            if val:
                flow_data[key] = val

        response_data = process_flow_message(conversation, effective_message, flow_step, flow_data)
        template_name = TEMPLATE_MAP.get(
            response_data.get("message_type", "text"),
            "website/partials/chat_message.html",
        )
    else:
        response_data = process_message(conversation, effective_message)
        template_name = "website/partials/chat_message.html"

    assistant_msg = Message.objects.create(
        conversation=conversation,
        role=Message.Role.ASSISTANT,
        content=response_data.get("content", ""),
        metadata={
            **response_data.get("metadata", {}),
            "message_type": response_data.get("message_type", "text"),
            "ui_data": response_data.get("ui_data", {}),
        },
    )

    ctx = {
        "user_message": user_msg,
        "assistant_message": assistant_msg,
        "metadata": response_data.get("metadata", {}),
        "ui_data": response_data.get("ui_data", {}),
        "message_type": response_data.get("message_type", "text"),
    }
    return render(request, template_name, ctx)


@require_GET
def calendar_download(request: HttpRequest, booking_id: str) -> HttpResponse:
    """Serve an .ics calendar file for a confirmed booking."""
    from apps.bookings.models import Booking
    from .email import generate_ics

    try:
        booking = Booking.objects.get(
            id=booking_id,
            status__in=[Booking.Status.CONFIRMED, Booking.Status.COMPLETED],
        )
    except Booking.DoesNotExist:
        return HttpResponse("Booking not found.", status=404)

    ics_data = generate_ics(booking)
    response = HttpResponse(ics_data, content_type="text/calendar; charset=utf-8")
    response["Content-Disposition"] = f'attachment; filename="coresync-{booking.confirmation_number}.ics"'
    return response

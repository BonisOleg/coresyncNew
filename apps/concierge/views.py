"""
Concierge HTMX views — web chat interface.
"""

from __future__ import annotations

import json
import logging
import uuid

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_POST

from .engine import process_message
from .models import Conversation, Message

logger = logging.getLogger(__name__)


def concierge_panel(request: HttpRequest) -> HttpResponse:
    """Render the concierge chat panel (HTMX partial)."""
    session_id = request.session.get("concierge_session", str(uuid.uuid4()))
    request.session["concierge_session"] = session_id
    context_param = request.GET.get("context")

    conversation, created = Conversation.objects.get_or_create(
        session_id=session_id,
        defaults={"channel": Conversation.Channel.WEB},
    )

    # If new conversation or context provided, add the welcome message
    separator_id = None
    if created or context_param == "explore_booking":
        content = "Welcome. I'm your CoreSync concierge. "
        buttons = [
            {"label": "Book an evening", "action": "book"},
            {"label": "Explore membership", "action": "membership"},
            {"label": "Just exploring", "action": "explore"},
        ]

        if context_param == "explore_booking":
            content = "Welcome. I'm here to help you explore CoreSync Private, book your visit, or just feel the space. What would you like to start with?"
            buttons = [
                {"label": "Explore the space", "action": "explore"},
                {"label": "Booking options", "action": "booking"},
                {"label": "Feeling the space", "action": "feeling"},
            ]

        msg = Message.objects.create(
            conversation=conversation,
            role=Message.Role.ASSISTANT,
            content=content,
            metadata={
                "buttons": buttons
            },
        )
        separator_id = msg.id

    messages = conversation.messages.all()

    # Always mark the last message as separator so chat opens "fresh"
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
    Sends message to Gemini, returns the AI response as HTML partial.
    """
    session_id = request.session.get("concierge_session", str(uuid.uuid4()))
    user_message = request.POST.get("message", "").strip()
    action = request.POST.get("action", "")

    if not user_message and not action:
        return HttpResponse("")

    # Get or create conversation
    conversation, _ = Conversation.objects.get_or_create(
        session_id=session_id,
        defaults={"channel": Conversation.Channel.WEB},
    )

    # If action button was clicked, use it as the message
    effective_message = user_message or action

    # Save user message
    user_msg = Message.objects.create(
        conversation=conversation,
        role=Message.Role.USER,
        content=effective_message,
        metadata={"action": action} if action else {},
    )

    # Process through Gemini engine
    response_data = process_message(conversation, effective_message)

    # Save assistant response
    assistant_msg = Message.objects.create(
        conversation=conversation,
        role=Message.Role.ASSISTANT,
        content=response_data.get("content", ""),
        metadata=response_data.get("metadata", {}),
    )

    context = {
        "user_message": user_msg,
        "assistant_message": assistant_msg,
        "metadata": response_data.get("metadata", {}),
    }
    return render(request, "website/partials/chat_message.html", context)

"""
Concierge flow engine — deterministic state machine for structured booking
and membership flows. Runs alongside the Gemini engine (engine.py) which
handles free-form conversation.
"""

from __future__ import annotations

import logging
from typing import Any

from .models import Conversation

logger = logging.getLogger(__name__)

TEMPLATE_MAP: dict[str, str] = {
    "text": "website/partials/chat_message.html",
    "buttons": "website/partials/chat_message.html",
    "calendar": "website/partials/chat_calendar.html",
    "time_slots": "website/partials/chat_time_slots.html",
    "experience_tier": "website/partials/chat_experience_tier.html",
    "input_fields": "website/partials/chat_input_fields.html",
    "summary": "website/partials/chat_summary.html",
    "payment": "website/partials/chat_payment.html",
    "confirmation": "website/partials/chat_confirmation.html",
    "environment": "website/partials/chat_environment.html",
    "membership": "website/partials/chat_membership.html",
}


def get_flow_state(conversation: Conversation) -> dict[str, Any]:
    """Read flow state from conversation context, returning empty dict if none."""
    ctx = conversation.context or {}
    return {
        "flow": ctx.get("flow"),
        "step": ctx.get("step"),
        "data": ctx.get("data", {}),
    }


def set_flow_state(
    conversation: Conversation,
    flow: str | None,
    step: str,
    data: dict[str, Any] | None = None,
) -> None:
    """Persist flow state into conversation context."""
    ctx = conversation.context or {}
    if flow is None:
        ctx.pop("flow", None)
        ctx.pop("step", None)
        ctx.pop("data", None)
    else:
        ctx["flow"] = flow
        ctx["step"] = step
        if data is not None:
            ctx["data"] = data
    conversation.context = ctx
    conversation.save(update_fields=["context"])


def merge_flow_data(
    conversation: Conversation, new_data: dict[str, Any]
) -> dict[str, Any]:
    """Merge new user input into the accumulated flow data and persist."""
    ctx = conversation.context or {}
    existing = ctx.get("data", {})
    existing.update({k: v for k, v in new_data.items() if v})
    ctx["data"] = existing
    conversation.context = ctx
    conversation.save(update_fields=["context"])
    return existing


def process_flow_message(
    conversation: Conversation,
    user_input: str,
    flow_step: str,
    flow_data: dict[str, Any],
) -> dict[str, Any]:
    """
    Route a flow step to the appropriate handler.

    Returns:
        dict with keys: content, message_type, ui_data, metadata
    """
    accumulated = merge_flow_data(conversation, flow_data)

    if flow_step == "done":
        set_flow_state(conversation, flow=None, step="")
        return {
            "content": "No problem. I'm here whenever you're ready.",
            "message_type": "buttons",
            "ui_data": {
                "buttons": [
                    {"label": "Book a session", "flow_step": "start_booking"},
                    {"label": "Explore membership", "flow_step": "start_membership"},
                ],
            },
            "metadata": {},
        }

    if flow_step.startswith("membership"):
        from .flows.membership import handle_membership_step

        result = handle_membership_step(conversation, flow_step, accumulated)
    else:
        from .flows.booking import handle_booking_step

        result = handle_booking_step(conversation, flow_step, accumulated)

    set_flow_state(
        conversation,
        flow=result.get("flow", get_flow_state(conversation).get("flow")),
        step=result.get("next_step", flow_step),
        data=accumulated,
    )

    return {
        "content": result["content"],
        "message_type": result.get("message_type", "text"),
        "ui_data": result.get("ui_data", {}),
        "metadata": result.get("metadata", {}),
    }

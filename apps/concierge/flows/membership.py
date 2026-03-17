"""
Membership flow — structured step-by-step handlers for membership
exploration, benefits reveal, pricing, and reservation.
"""

from __future__ import annotations

import logging
from typing import Any

from apps.concierge.models import Conversation

logger = logging.getLogger(__name__)

MEMBERSHIP_BENEFITS = [
    "1 Essential Ritual included each year",
    "Preferred member session rates",
    "Priority booking access for high-demand times",
    "Access to the CoreSync app to personalize the experience",
    "One complimentary house bottle during each visit",
    "Preferred pricing on premium bottles, cigars, and ritual gifts",
    "$250 birthday credit each year",
    "Guest booking privilege",
    "Early access to new CoreSync experiences and the backyard",
]

MEMBERSHIP_PRICE = 2200
FOUNDING_LIMIT = 100


def handle_membership_step(
    conversation: Conversation,
    step: str,
    data: dict[str, Any],
) -> dict[str, Any]:
    """Route to the correct membership step handler."""
    handlers: dict[str, Any] = {
        "membership_intro": _intro,
        "membership_reveal": _reveal,
        "membership_price": _price,
        "membership_invite": _invite,
        "membership_learn_more": _learn_more,
        "membership_activate": _activate,
        "start_membership": _intro,
    }

    handler = handlers.get(step, _intro)
    return handler(conversation, data)


def _intro(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": (
            "CoreSync Private Club is designed for couples who plan to return "
            "and want priority access to the CoreSync experience. "
            "Would you like me to briefly explain how membership works?"
        ),
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_intro",
        "ui_data": {
            "buttons": [
                {"label": "Yes, show me", "flow_step": "membership_reveal"},
                {"label": "Maybe later", "flow_step": "done"},
            ],
        },
    }


def _reveal(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": "Membership gives couples preferred access and privileges at CoreSync.",
        "message_type": "membership",
        "flow": "membership",
        "next_step": "membership_reveal",
        "ui_data": {
            "benefits": MEMBERSHIP_BENEFITS,
            "scarcity_line": f"Founding Membership is limited to the first {FOUNDING_LIMIT} couples.",
            "next_flow_step": "membership_price",
        },
    }


def _price(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": (
            f"Annual membership is ${MEMBERSHIP_PRICE:,}.\n\n"
            "Many members recover the cost of membership within their first few visits "
            "while gaining priority access to the experience."
        ),
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_price",
        "ui_data": {
            "buttons": [
                {"label": "Yes, reserve membership", "flow_step": "membership_activate"},
                {"label": "I want to learn more", "flow_step": "membership_learn_more"},
                {"label": "Not right now", "flow_step": "done"},
            ],
        },
        "metadata": {"price": MEMBERSHIP_PRICE},
    }


def _invite(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": "Would you like me to reserve a CoreSync membership for you?",
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_invite",
        "ui_data": {
            "buttons": [
                {"label": "Yes, reserve membership", "flow_step": "membership_activate"},
                {"label": "I want to learn more", "flow_step": "membership_learn_more"},
                {"label": "Not right now", "flow_step": "done"},
            ],
        },
    }


def _learn_more(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": (
            "Members typically join because they plan to visit multiple times "
            "and want priority booking access, preferred pricing, and personalized "
            "control of the experience through the CoreSync app.\n\n"
            f"Founding memberships are limited to {FOUNDING_LIMIT} couples."
        ),
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_learn_more",
        "ui_data": {
            "buttons": [
                {"label": "Reserve membership", "flow_step": "membership_activate"},
                {"label": "Continue browsing", "flow_step": "done"},
            ],
        },
    }


def _activate(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    return {
        "content": "Would you like to activate membership today or add it when booking your first experience?",
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_activate",
        "ui_data": {
            "buttons": [
                {"label": "Activate membership now", "flow_step": "membership_payment"},
                {"label": "Add it to my booking", "flow_step": "start_booking"},
            ],
        },
    }


def _membership_upsell_after_booking(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any] | None:
    """Post-booking membership upsell (Moment 2 from spec). Returns None to skip."""
    ctx = conversation.context or {}
    if ctx.get("membership_offered"):
        return None

    ctx["membership_offered"] = True
    conversation.context = ctx
    conversation.save(update_fields=["context"])

    return {
        "content": (
            "Members receive priority booking and preferred access to CoreSync Private. "
            "Would you like to explore membership?"
        ),
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "membership_intro",
        "ui_data": {
            "buttons": [
                {"label": "View membership", "flow_step": "membership_reveal"},
                {"label": "Maybe later", "flow_step": "done"},
            ],
        },
    }

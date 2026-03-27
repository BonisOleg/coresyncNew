"""
Membership flow — structured step-by-step handlers for membership
exploration, benefits reveal, pricing, and reservation.
"""

from __future__ import annotations

import logging
from datetime import date, timedelta
from typing import Any

from django.conf import settings
from django.utils import timezone

from apps.concierge.models import Conversation
from apps.guests.models import GuestMembership, Membership

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
        "membership_payment": _membership_payment,
        "membership_confirmation": _membership_confirmation,
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


def _membership_payment(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Collect payment for membership activation via Stripe."""
    guest = conversation.guest
    if not guest:
        return {
            "content": (
                "To process your membership, I'll need to verify your identity first. "
                "Let's start with a quick booking — membership can be added during the process."
            ),
            "message_type": "buttons",
            "flow": "booking",
            "next_step": "start_booking",
            "ui_data": {
                "buttons": [
                    {"label": "Start booking", "flow_step": "start_booking"},
                ],
            },
        }

    membership_tier = Membership.objects.filter(is_active=True).first()
    if not membership_tier:
        membership_tier = Membership.objects.create(
            name="Founding Membership",
            description="CoreSync Private Club — Founding Member",
        )

    guest_membership = GuestMembership.objects.create(
        guest=guest,
        membership=membership_tier,
        status=GuestMembership.Status.PAUSED,
        start_date=date.today(),
        end_date=date.today() + timedelta(days=365),
    )

    ctx = conversation.context or {}
    ctx["pending_membership_id"] = str(guest_membership.id)
    conversation.context = ctx
    conversation.save(update_fields=["context"])

    try:
        from apps.concierge.stripe_utils import create_membership_payment_intent

        pi = create_membership_payment_intent(
            guest, MEMBERSHIP_PRICE, str(guest_membership.id),
        )
        guest_membership.stripe_subscription_id = pi["id"]
        guest_membership.save(update_fields=["stripe_subscription_id"])

        return {
            "content": f"Complete your payment of ${MEMBERSHIP_PRICE:,} to activate your CoreSync membership.",
            "message_type": "payment",
            "flow": "membership",
            "next_step": "membership_confirmation",
            "ui_data": {
                "client_secret": pi["client_secret"],
                "amount": MEMBERSHIP_PRICE,
                "currency": "USD",
                "booking_id": str(guest_membership.id),
                "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
                "next_flow_step": "membership_confirmation",
            },
            "metadata": {"guest_membership_id": str(guest_membership.id)},
        }
    except Exception as exc:
        logger.warning("Stripe membership payment failed: %s", exc)
        guest_membership.status = GuestMembership.Status.ACTIVE
        guest_membership.save(update_fields=["status"])
        return _membership_confirmed_response(guest_membership)


def _membership_confirmation(
    conversation: Conversation, data: dict[str, Any]
) -> dict[str, Any]:
    """Verify membership payment and activate."""
    ctx = conversation.context or {}
    gm_id = ctx.get("pending_membership_id")

    guest_membership = None
    if gm_id:
        guest_membership = GuestMembership.objects.filter(id=gm_id).first()

    if not guest_membership:
        return _intro(conversation, data)

    if guest_membership.status != GuestMembership.Status.ACTIVE:
        if guest_membership.stripe_subscription_id:
            from apps.concierge.stripe_utils import confirm_booking_payment

            if not confirm_booking_payment(guest_membership.stripe_subscription_id):
                return {
                    "content": "Membership payment could not be verified. Please try again or contact support.",
                    "message_type": "buttons",
                    "flow": "membership",
                    "next_step": "membership_payment",
                    "ui_data": {
                        "buttons": [
                            {"label": "Try again", "flow_step": "membership_payment"},
                            {"label": "Contact support", "flow_step": "done"},
                        ],
                        "error": "Payment verification failed.",
                    },
                }

        guest_membership.status = GuestMembership.Status.ACTIVE
        guest_membership.save(update_fields=["status"])

    return _membership_confirmed_response(guest_membership)


def _membership_confirmed_response(guest_membership: GuestMembership) -> dict[str, Any]:
    """Build the membership confirmation response."""
    return {
        "content": (
            "Welcome to CoreSync Private Club. "
            "Your Founding Membership is now active.\n\n"
            "You now have priority booking access, preferred session rates, "
            "and all member privileges."
        ),
        "message_type": "buttons",
        "flow": "membership",
        "next_step": "done",
        "ui_data": {
            "buttons": [
                {"label": "Book a session", "flow_step": "start_booking"},
                {"label": "Done", "flow_step": "done"},
            ],
        },
        "metadata": {
            "action_triggered": "membership_activated",
            "guest_membership_id": str(guest_membership.id),
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

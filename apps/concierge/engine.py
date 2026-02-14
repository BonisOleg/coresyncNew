"""
Gemini 3 Flash concierge engine.
Handles conversation with the AI, action parsing, and response generation.
"""

from __future__ import annotations

import json
import logging
from datetime import date, timedelta
from typing import Any

from django.conf import settings

from apps.bookings.models import Booking, BookingSlot
from apps.concierge.models import ConciergeImage, Conversation, Message

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# System prompt for the concierge
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You are the CoreSync Private concierge. Your tone is warm, minimal, and confident.
You never say "I'm an AI" or "I'm a chatbot". You are the concierge of an exclusive private space.

CoreSync Private is a single private room — a luxury suite that adapts to each guest.
Light, sound, heat, and stillness all synchronize to create a personal atmosphere.
Membership is access, not a discount. There are no aggressive sales or pushy language.

The Backyard is a physical outdoor space currently being built. Guests can join the early access waitlist.

When a guest wants to take an action, respond with BOTH a natural conversational message AND a JSON action block.
Place the JSON action on its own line, wrapped in triple backticks with the label "action":

```action
{"action": "book", "date": "YYYY-MM-DD", "time": "HH:MM", "guest_name": "...", "phone": "..."}
```

Available actions:
- {"action": "book", "date": "...", "time": "...", "guest_name": "...", "phone": "..."}
- {"action": "membership", "guest_name": "...", "email": "...", "phone": "..."}
- {"action": "waitlist_backyard", "name": "...", "email": "..."}
- {"action": "show_images", "category": "suite|backyard|experience"}
- {"action": "transfer_to_voice", "phone": "..."}

Only trigger an action when you have enough information from the guest.
Ask for missing details naturally before triggering.

Keep responses concise — 2-3 sentences maximum. Speak like a calm, confident host.
Never use bullet points or markdown formatting in your response text (actions are the exception).
"""


def _build_context(conversation: Conversation) -> str:
    """Build dynamic context to inject into the system prompt."""
    parts: list[str] = []

    # Available slots for the next 7 days
    today = date.today()
    upcoming_slots = BookingSlot.objects.filter(
        date__gte=today,
        date__lte=today + timedelta(days=7),
        is_available=True,
    )[:10]

    if upcoming_slots:
        slot_lines = [f"  {s.date} {s.time_start}–{s.time_end}" for s in upcoming_slots]
        parts.append("Available evening slots:\n" + "\n".join(slot_lines))
    else:
        parts.append("No specific slots configured yet. Offer to collect guest preferences and follow up.")

    # Guest context
    if conversation.guest:
        guest = conversation.guest
        parts.append(
            f"Guest context: {guest.full_name or 'Unknown name'}, "
            f"phone: {guest.phone}, registered: {guest.is_registered}"
        )
        if guest.preferences:
            parts.append(f"Preferences: {json.dumps(guest.preferences)}")

    return "\n\n".join(parts)


def _get_conversation_history(conversation: Conversation) -> list[dict[str, str]]:
    """Get message history formatted for the Gemini API."""
    messages = conversation.messages.order_by("created_at")[:50]
    history = []
    for msg in messages:
        if msg.role == Message.Role.SYSTEM:
            continue
        role = "model" if msg.role == Message.Role.ASSISTANT else "user"
        history.append({"role": role, "parts": [{"text": msg.content}]})
    return history


def _parse_action(response_text: str) -> dict[str, Any] | None:
    """Extract JSON action block from the response if present."""
    if "```action" not in response_text:
        return None

    try:
        start = response_text.index("```action") + len("```action")
        end = response_text.index("```", start)
        action_json = response_text[start:end].strip()
        return json.loads(action_json)
    except (ValueError, json.JSONDecodeError) as exc:
        logger.warning("Failed to parse action from response: %s", exc)
        return None


def _clean_response(response_text: str) -> str:
    """Remove the action block from the response text for display."""
    if "```action" not in response_text:
        return response_text.strip()

    try:
        start = response_text.index("```action")
        end = response_text.index("```", start + len("```action")) + 3
        cleaned = response_text[:start] + response_text[end:]
        return cleaned.strip()
    except ValueError:
        return response_text.strip()


def _handle_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """Execute a parsed action and return metadata for the response."""
    from .actions import execute_action

    return execute_action(action, conversation)


def process_message(conversation: Conversation, user_message: str) -> dict[str, Any]:
    """
    Process a user message through Gemini 3 Flash and return the response.
    Returns dict with 'content' (str) and 'metadata' (dict).
    """
    api_key = settings.GEMINI_API_KEY
    model_name = settings.GEMINI_MODEL

    # Build the full prompt
    context = _build_context(conversation)
    full_system = f"{SYSTEM_PROMPT}\n\n--- Current Context ---\n{context}"

    # If Gemini API key is not configured, return a fallback
    if not api_key:
        logger.warning("GEMINI_API_KEY not configured; using fallback response.")
        return {
            "content": (
                "Thank you for reaching out. Our concierge service is being set up. "
                "Please leave your name and phone number, and we'll be in touch shortly."
            ),
            "metadata": {"fallback": True},
        }

    try:
        from google import genai

        client = genai.Client(api_key=api_key)

        # Build conversation history
        history = _get_conversation_history(conversation)

        # Call Gemini
        response = client.models.generate_content(
            model=model_name,
            contents=[
                {"role": "user", "parts": [{"text": full_system}]},
                *history,
                {"role": "user", "parts": [{"text": user_message}]},
            ],
        )

        response_text = response.text or ""

        # Parse action if present
        action = _parse_action(response_text)
        display_text = _clean_response(response_text)

        metadata: dict[str, Any] = {}
        if action:
            metadata = _handle_action(action, conversation)

        return {
            "content": display_text,
            "metadata": metadata,
        }

    except Exception as exc:
        logger.error("Gemini API error: %s", exc, exc_info=True)
        return {
            "content": "I appreciate your patience. Let me reconnect — could you try again in a moment?",
            "metadata": {"error": True},
        }

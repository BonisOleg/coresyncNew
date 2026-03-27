"""
Gemini concierge engine.
Handles conversation with the AI, action parsing, and response generation.
"""

from __future__ import annotations

import json
import logging
import re
import time
from datetime import date, timedelta
from typing import Any

from django.conf import settings

from apps.bookings.models import Booking, BookingSlot
from apps.concierge.models import ConciergeImage, Conversation, Message

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# System prompt for the concierge
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """\
You are the concierge of CoreSync Private — an exclusive single-room luxury suite \
designed for couples. You speak like a calm, confident host at a world-class private club. \
Never reveal you are an AI, chatbot, or language model.

=== ABOUT CORESYNC PRIVATE ===

CoreSync Private is one private room — a luxury suite that physically adapts to each \
guest. Light, sound, scent, temperature, and visual atmosphere all synchronize to create \
a personal environment. Guests choose from curated scenes such as Italy, Japan, or \
Iceland, and the room transforms to match.

Sessions are evening-based, typically running from 6 PM to 11 PM (approximately 5 hours).

Pricing:
- Full Experience — $350 (includes curated food, beverages, and full atmospheric control)
- Experience without food — $250 (full atmospheric control without food service)
- If a guest selects Full Experience, they choose between dairy or meat for their meal.

The Backyard is a physical outdoor extension of CoreSync Private. It is currently under \
construction. Guests can join the early-access waitlist to be notified when it opens.

=== MEMBERSHIP ===

CoreSync Private Club is an annual membership at $2,200 per year. Founding Membership \
is limited to the first 100 couples.

Member benefits: one Essential Ritual included each year, preferred session rates, \
priority booking access, CoreSync app personalization, one complimentary house bottle \
per visit, preferred pricing on premium items, $250 birthday credit, guest booking \
privilege, and early access to new experiences and the Backyard.

Sales philosophy — NEVER say "buy membership" or use pushy language. Instead say \
"Many guests choose membership because…" or "Members receive…" or "Would you like \
to explore membership?" This approach feels premium and inviting.

=== HOW TO RESPOND ===

Always reply with a short natural message (2–3 sentences maximum). After your text, \
you MUST include a buttons block so the guest always has a clear next step. Place the \
buttons on their own line using this exact format:

```buttons
[{"label": "Book a session", "flow_step": "start_booking"}, {"label": "Tell me more", "action": "explore"}]
```

Available button types (choose the ones that fit the conversation):
- {"label": "Book a session", "flow_step": "start_booking"}
- {"label": "Explore membership", "flow_step": "start_membership"}
- {"label": "Show me the space", "action": "show_images"}
- {"label": "Tell me more", "action": "explore"}
- {"label": "Join the waitlist", "action": "waitlist"}

=== INTENT RECOGNITION ===

BOOKING: If the guest says they want to book, reserve, visit, or schedule — respond \
warmly and offer the booking button. Do NOT try to collect dates, names, or phone \
numbers yourself. The structured booking flow handles all data collection.

PHOTOS / SPACE: If the guest asks to see photos, the room, or wants a glimpse — \
include a show_images action block AND follow-up buttons. Example:
```action
{"action": "show_images", "category": "suite"}
```

PRICING: If the guest asks about cost, price, or how much — explain both tiers \
naturally and suggest booking.

MEMBERSHIP: If the guest asks about membership, the club, or returning often — \
explain briefly and offer the membership button. Use the soft-sell language above.

BACKYARD: If the guest asks about the backyard or outdoor space — explain it is \
being built and offer the waitlist.

GENERAL QUESTIONS: For any other question about the experience, answer warmly \
using your knowledge above, then suggest a relevant next step via buttons.

=== STRICT RULES ===

1. NEVER collect booking details (date, name, phone) via free text. Always direct \
   to the structured booking flow using the "Book a session" button.
2. ALWAYS end your response with a ```buttons block. Every response needs buttons.
3. Keep text to 2–3 sentences. No bullet points, numbered lists, or markdown in \
   your visible text.
4. Never mention that you have "actions" or "buttons" — they appear naturally in \
   the interface.
5. If the guest says something unclear, respond warmly and offer the three main \
   options: book, explore membership, or just explore.
6. When you show images, ALWAYS also include booking and membership buttons after.
"""


def _build_context(conversation: Conversation) -> str:
    """Build dynamic context to inject into the system prompt."""
    from datetime import datetime

    parts: list[str] = []

    parts.append(f"Today: {date.today().strftime('%A, %B %d, %Y')}, "
                 f"current time: {datetime.now().strftime('%I:%M %p')}")

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
        parts.append("No specific slots configured yet. Offer to start the booking flow and the system will show available dates.")

    image_counts = {}
    for cat_choice in ConciergeImage.Category.choices:
        cat_key = cat_choice[0]
        cnt = ConciergeImage.objects.filter(category=cat_key).count()
        if cnt:
            image_counts[cat_key] = cnt
    if image_counts:
        parts.append(f"Available photos: {json.dumps(image_counts)} — you can show these when asked.")
    else:
        parts.append("No photos available in the gallery yet.")

    if conversation.guest:
        guest = conversation.guest
        parts.append(
            f"Guest: {guest.full_name or 'Unknown name'}, "
            f"phone: {guest.phone}, registered: {guest.is_registered}"
        )
        if guest.preferences:
            parts.append(f"Preferences: {json.dumps(guest.preferences)}")

        active_memberships = guest.memberships.filter(status="active")
        if active_memberships.exists():
            parts.append("This guest is an ACTIVE member. Greet them warmly as a member.")
        else:
            parts.append("This guest is not a member. You may gently mention membership benefits at the right moment.")

    return "\n\n".join(parts)


def _get_conversation_history(conversation: Conversation) -> list[dict[str, Any]]:
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


def _parse_buttons(response_text: str) -> list[dict[str, Any]] | None:
    """Extract buttons JSON array from the response if present."""
    if "```buttons" not in response_text:
        return None

    try:
        start = response_text.index("```buttons") + len("```buttons")
        end = response_text.index("```", start)
        buttons_json = response_text[start:end].strip()
        parsed = json.loads(buttons_json)
        if isinstance(parsed, list) and parsed:
            return parsed
        return None
    except (ValueError, json.JSONDecodeError) as exc:
        logger.warning("Failed to parse buttons from response: %s", exc)
        return None


def _strip_fenced_block(text: str, label: str) -> str:
    """Remove a triple-backtick fenced block with the given label from text."""
    marker = f"```{label}"
    if marker not in text:
        return text
    try:
        start = text.index(marker)
        end = text.index("```", start + len(marker)) + 3
        return (text[:start] + text[end:]).strip()
    except ValueError:
        return text


def _clean_response(response_text: str) -> str:
    """Remove action and buttons blocks from the response text for display."""
    cleaned = _strip_fenced_block(response_text, "action")
    cleaned = _strip_fenced_block(cleaned, "buttons")
    return cleaned.strip()


def _extract_retry_delay(error_message: str) -> float:
    """Extract retry delay in seconds from a 429 error message."""
    match = re.search(r"retry in (\d+(?:\.\d+)?)s", str(error_message))
    if match:
        return min(float(match.group(1)), 30.0)
    return 5.0


def _default_buttons() -> list[dict[str, str]]:
    """Fallback buttons when Gemini doesn't produce any."""
    return [
        {"label": "Book a session", "flow_step": "start_booking"},
        {"label": "Explore membership", "flow_step": "start_membership"},
    ]


def _handle_action(action: dict[str, Any], conversation: Conversation) -> dict[str, Any]:
    """Execute a parsed action and return metadata for the response."""
    from .actions import execute_action

    return execute_action(action, conversation)


def process_message(conversation: Conversation, user_message: str) -> dict[str, Any]:
    """
    Process a user message through Gemini and return the response.
    Returns dict with 'content' (str) and 'metadata' (dict).
    """
    api_key = settings.GEMINI_API_KEY
    model_name = settings.GEMINI_MODEL

    # Build the full system instruction
    context = _build_context(conversation)
    full_system = f"{SYSTEM_PROMPT}\n\n--- Current Context ---\n{context}"

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
        from google.genai import types
        from google.genai.errors import ClientError

        client = genai.Client(api_key=api_key)
        history = _get_conversation_history(conversation)

        def _call_api() -> str:
            response = client.models.generate_content(
                model=model_name,
                contents=[
                    *history,
                    {"role": "user", "parts": [{"text": user_message}]},
                ],
                config=types.GenerateContentConfig(
                    system_instruction=full_system,
                ),
            )
            return response.text or ""

        try:
            response_text = _call_api()
        except ClientError as exc:
            if exc.status_code == 429:
                delay = _extract_retry_delay(str(exc))
                logger.warning("Gemini 429 — retrying after %.1fs: %s", delay, exc)
                time.sleep(delay)
                response_text = _call_api()
            else:
                raise

        action = _parse_action(response_text)
        buttons = _parse_buttons(response_text)
        display_text = _clean_response(response_text)

        metadata: dict[str, Any] = {}
        if action:
            metadata = _handle_action(action, conversation)
        if buttons:
            metadata.setdefault("buttons", buttons)

        if not metadata.get("buttons"):
            metadata["buttons"] = _default_buttons()

        return {
            "content": display_text,
            "metadata": metadata,
        }

    except Exception as exc:
        from google.genai.errors import ClientError

        if isinstance(exc, ClientError) and exc.status_code == 429:
            logger.warning("Gemini quota exhausted (429): %s", exc)
            return {
                "content": "I'll be right with you — just a moment, please.",
                "metadata": {"rate_limited": True},
            }

        logger.error("Gemini API error: %s", exc, exc_info=True)
        return {
            "content": "I appreciate your patience. Let me reconnect — could you try again in a moment?",
            "metadata": {"error": True},
        }

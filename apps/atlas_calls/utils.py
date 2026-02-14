"""
Atlas.AI utility functions — initiate outbound calls.
"""

from __future__ import annotations

import logging

import httpx
from django.conf import settings

logger = logging.getLogger(__name__)


def initiate_atlas_call(phone_number: str, context: dict | None = None) -> str | None:
    """
    Trigger an outbound AI voice call via Atlas.AI.
    Returns the Atlas call ID on success, None on failure.
    """
    api_key = settings.ATLAS_API_KEY
    agent_id = settings.ATLAS_AGENT_ID

    if not api_key or not agent_id:
        logger.warning("Atlas.AI not configured; skipping call initiation.")
        return None

    payload = {
        "agent_id": agent_id,
        "phone_number": phone_number,
        "metadata": context or {},
    }

    try:
        response = httpx.post(
            "https://api.youratlas.com/v1/calls",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=15,
        )
        response.raise_for_status()
        data = response.json()
        call_id = data.get("call_id", "")
        logger.info("Atlas.AI call initiated: %s -> %s", phone_number, call_id)
        return call_id

    except httpx.HTTPError as exc:
        logger.error("Atlas.AI call initiation failed for %s: %s", phone_number, exc)
        return None

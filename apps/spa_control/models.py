"""
Abstract IoT device interface for SPA control via Flutter app.
Actual hardware integration is a future adapter layer.
"""

from __future__ import annotations

import uuid
from typing import Any

from django.db import models


class DeviceType(models.Model):
    """Category of IoT device (light, thermostat, audio, etc.)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=60, unique=True)
    # Capabilities this device type supports (e.g. {"brightness": true, "color": true})
    capabilities: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Device(models.Model):
    """A specific IoT device instance in the SPA."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    device_type = models.ForeignKey(
        DeviceType,
        on_delete=models.PROTECT,
        related_name="devices",
    )
    name = models.CharField(max_length=120)
    room = models.CharField(max_length=100, blank=True, default="")
    # Current device state (e.g. {"power": "on", "brightness": 80})
    current_state: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]
    is_online = models.BooleanField(default=False)

    class Meta:
        ordering = ["room", "name"]

    def __str__(self) -> str:
        location = f" ({self.room})" if self.room else ""
        return f"{self.name}{location}"


class GuestPreset(models.Model):
    """Saved device settings preset for a guest."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey(
        "guests.Guest",
        on_delete=models.CASCADE,
        related_name="spa_presets",
    )
    name = models.CharField(max_length=120)
    # JSON mapping of device_id -> desired state
    settings: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.name}"

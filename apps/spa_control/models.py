"""
Abstract IoT device interface for SPA control via Flutter app.
Includes scenes (screen + music), scent profiles, and device control.
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
    settings: dict[str, Any] = models.JSONField(default=dict, blank=True)  # type: ignore[assignment]

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.name}"


# ---------------------------------------------------------------------------
# Scenes — ambient screen visuals with optional music
# ---------------------------------------------------------------------------


class Scene(models.Model):
    """An ambient screen scene (video loop) for the room display."""

    class Category(models.TextChoices):
        RELAXATION = "relaxation", "Relaxation"
        ENERGY = "energy", "Energy"
        ROMANCE = "romance", "Romance"
        FOCUS = "focus", "Focus"
        NATURE = "nature", "Nature"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True, default="")
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.RELAXATION)
    screen_video_url = models.URLField(max_length=500, blank=True, default="")
    thumbnail_url = models.URLField(max_length=500, blank=True, default="")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "name"]

    def __str__(self) -> str:
        return f"{self.name} ({self.category})"


class SceneMusic(models.Model):
    """A music track available within a scene."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    scene = models.ForeignKey(Scene, on_delete=models.CASCADE, related_name="tracks")
    title = models.CharField(max_length=200)
    artist = models.CharField(max_length=200, blank=True, default="")
    audio_url = models.URLField(max_length=500, blank=True, default="")
    duration_seconds = models.PositiveIntegerField(default=0)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "title"]

    def __str__(self) -> str:
        return f"{self.title} — {self.scene.name}"


class ActiveRoomScene(models.Model):
    """Currently active scene for a guest's room session."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="active_scenes")
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.SET_NULL, null=True, blank=True, related_name="active_scenes",
    )
    scene = models.ForeignKey(Scene, on_delete=models.CASCADE, related_name="activations")
    music_enabled = models.BooleanField(default=False)
    current_track = models.ForeignKey(
        SceneMusic, on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
    )
    activated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-activated_at"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.scene.name}"


# ---------------------------------------------------------------------------
# Scent — fragrance diffuser control
# ---------------------------------------------------------------------------


class ScentProfile(models.Model):
    """A scent/fragrance option for the room diffuser."""

    class Category(models.TextChoices):
        FLORAL = "floral", "Floral"
        WOODY = "woody", "Woody"
        CITRUS = "citrus", "Citrus"
        HERBAL = "herbal", "Herbal"
        FRESH = "fresh", "Fresh"
        ORIENTAL = "oriental", "Oriental"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True, default="")
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.FLORAL)
    intensity_default = models.PositiveIntegerField(default=5)
    intensity_min = models.PositiveIntegerField(default=1)
    intensity_max = models.PositiveIntegerField(default=10)
    icon_url = models.URLField(max_length=500, blank=True, default="")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "name"]

    def __str__(self) -> str:
        return f"{self.name} ({self.category})"


class ActiveScent(models.Model):
    """Currently active scent for a guest's room session."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guest = models.ForeignKey("guests.Guest", on_delete=models.CASCADE, related_name="active_scents")
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.SET_NULL, null=True, blank=True, related_name="active_scents",
    )
    scent_profile = models.ForeignKey(ScentProfile, on_delete=models.CASCADE, related_name="activations")
    intensity = models.PositiveIntegerField(default=5)
    activated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-activated_at"]

    def __str__(self) -> str:
        return f"{self.guest} — {self.scent_profile.name} (intensity: {self.intensity})"

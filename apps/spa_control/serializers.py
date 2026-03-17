"""Serializers for SPA device control, scenes, and scent."""

from __future__ import annotations

from rest_framework import serializers

from .models import (
    ActiveRoomScene,
    ActiveScent,
    Device,
    DeviceType,
    GuestPreset,
    Scene,
    SceneMusic,
    ScentProfile,
)


class DeviceTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceType
        fields = ("id", "name", "capabilities")


class DeviceSerializer(serializers.ModelSerializer):
    device_type = DeviceTypeSerializer(read_only=True)

    class Meta:
        model = Device
        fields = ("id", "device_type", "name", "room", "current_state", "is_online")


class DeviceControlSerializer(serializers.Serializer):
    """Input for controlling a device."""
    state = serializers.DictField()


class GuestPresetSerializer(serializers.ModelSerializer):
    class Meta:
        model = GuestPreset
        fields = ("id", "name", "settings", "created_at")
        read_only_fields = ("id", "created_at")


# ---------------------------------------------------------------------------
# Scenes
# ---------------------------------------------------------------------------


class SceneMusicSerializer(serializers.ModelSerializer):
    class Meta:
        model = SceneMusic
        fields = ("id", "title", "artist", "audio_url", "duration_seconds", "order")


class SceneSerializer(serializers.ModelSerializer):
    tracks = SceneMusicSerializer(many=True, read_only=True)

    class Meta:
        model = Scene
        fields = (
            "id", "name", "description", "category",
            "screen_video_url", "thumbnail_url", "is_active", "order", "tracks",
        )


class SceneActivateSerializer(serializers.Serializer):
    scene_id = serializers.UUIDField()
    music_enabled = serializers.BooleanField(default=False)


class ActiveRoomSceneSerializer(serializers.ModelSerializer):
    scene = SceneSerializer(read_only=True)
    current_track = SceneMusicSerializer(read_only=True)

    class Meta:
        model = ActiveRoomScene
        fields = ("id", "scene", "music_enabled", "current_track", "activated_at")


# ---------------------------------------------------------------------------
# Scent
# ---------------------------------------------------------------------------


class ScentProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScentProfile
        fields = (
            "id", "name", "description", "category",
            "intensity_default", "intensity_min", "intensity_max",
            "icon_url", "is_active", "order",
        )


class ScentActivateSerializer(serializers.Serializer):
    scent_profile_id = serializers.UUIDField()
    intensity = serializers.IntegerField(min_value=1, max_value=10, default=5)


class ScentUpdateIntensitySerializer(serializers.Serializer):
    intensity = serializers.IntegerField(min_value=1, max_value=10)


class ActiveScentSerializer(serializers.ModelSerializer):
    scent_profile = ScentProfileSerializer(read_only=True)

    class Meta:
        model = ActiveScent
        fields = ("id", "scent_profile", "intensity", "activated_at")

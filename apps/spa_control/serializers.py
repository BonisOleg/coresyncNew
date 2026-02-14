"""Serializers for SPA device control."""

from __future__ import annotations

from rest_framework import serializers

from .models import Device, DeviceType, GuestPreset


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
    state = serializers.DictField(help_text="Desired device state (e.g. {'power': 'on', 'brightness': 80})")


class GuestPresetSerializer(serializers.ModelSerializer):
    class Meta:
        model = GuestPreset
        fields = ("id", "name", "settings", "created_at")
        read_only_fields = ("id", "created_at")

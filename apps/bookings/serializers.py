"""Serializers for bookings."""

from __future__ import annotations

from rest_framework import serializers

from .models import Booking, BookingSlot


class BookingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingSlot
        fields = ("id", "date", "time_start", "time_end", "is_available", "max_capacity")


class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = (
            "id",
            "guest",
            "date",
            "time_start",
            "time_end",
            "status",
            "preferences",
            "source",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "guest", "created_at", "updated_at")


class BookingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ("date", "time_start", "time_end", "preferences", "notes")


class BookingAdminSerializer(serializers.ModelSerializer):
    guest_name = serializers.CharField(source="guest.full_name", read_only=True)
    guest_phone = serializers.CharField(source="guest.phone", read_only=True)

    class Meta:
        model = Booking
        fields = (
            "id",
            "guest",
            "guest_name",
            "guest_phone",
            "date",
            "time_start",
            "time_end",
            "status",
            "preferences",
            "source",
            "notes",
            "calcom_event_id",
            "created_at",
            "updated_at",
        )

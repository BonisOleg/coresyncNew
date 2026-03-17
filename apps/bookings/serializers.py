"""Serializers for bookings, check-in, and session timer."""

from __future__ import annotations

from rest_framework import serializers

from .models import Booking, BookingSlot, CheckIn


class BookingSlotSerializer(serializers.ModelSerializer):
    remaining_capacity = serializers.IntegerField(read_only=True)

    class Meta:
        model = BookingSlot
        fields = ("id", "date", "time_start", "time_end", "is_available", "max_capacity", "remaining_capacity")


class BookingSerializer(serializers.ModelSerializer):
    has_checked_in = serializers.SerializerMethodField()

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
            "has_checked_in",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "guest", "created_at", "updated_at")

    def get_has_checked_in(self, obj: Booking) -> bool:
        return hasattr(obj, "checkin") and obj.checkin.status == CheckIn.Status.CHECKED_IN


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


class CheckInSerializer(serializers.ModelSerializer):
    booking = BookingSerializer(read_only=True)

    class Meta:
        model = CheckIn
        fields = ("id", "booking", "status", "checked_in_at", "checked_out_at")


class SessionTimerSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()
    date = serializers.DateField()
    time_start = serializers.TimeField()
    time_end = serializers.TimeField()
    checked_in_at = serializers.DateTimeField()
    total_seconds = serializers.IntegerField()
    remaining_seconds = serializers.IntegerField()

"""Serializers for Atlas.AI call records."""

from __future__ import annotations

from rest_framework import serializers

from .models import CallRecord


class CallRecordSerializer(serializers.ModelSerializer):
    guest_name = serializers.CharField(source="guest.full_name", read_only=True, default="")
    guest_phone = serializers.CharField(source="guest.phone", read_only=True, default="")

    class Meta:
        model = CallRecord
        fields = (
            "id",
            "guest",
            "guest_name",
            "guest_phone",
            "atlas_call_id",
            "phone_number",
            "direction",
            "status",
            "transcript",
            "outcome",
            "duration_seconds",
            "booking",
            "created_at",
        )

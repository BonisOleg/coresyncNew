"""Serializers for Guest profiles, membership, and authentication."""

from __future__ import annotations

from rest_framework import serializers

from .models import Guest, GuestMembership, Membership


class MembershipSerializer(serializers.ModelSerializer):
    class Meta:
        model = Membership
        fields = ("id", "name", "description", "is_active")


class GuestMembershipSerializer(serializers.ModelSerializer):
    membership = MembershipSerializer(read_only=True)

    class Meta:
        model = GuestMembership
        fields = (
            "id",
            "membership",
            "status",
            "start_date",
            "end_date",
            "created_at",
        )


class GuestProfileSerializer(serializers.ModelSerializer):
    memberships = GuestMembershipSerializer(many=True, read_only=True)

    class Meta:
        model = Guest
        fields = (
            "id",
            "phone",
            "email",
            "first_name",
            "last_name",
            "is_registered",
            "preferences",
            "memberships",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "phone", "is_registered", "created_at", "updated_at")


class GuestProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Guest
        fields = ("email", "first_name", "last_name", "preferences")


class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)


class VerifyOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    otp = serializers.CharField(max_length=6)


class GuestAdminSerializer(serializers.ModelSerializer):
    memberships = GuestMembershipSerializer(many=True, read_only=True)

    class Meta:
        model = Guest
        fields = (
            "id",
            "phone",
            "email",
            "first_name",
            "last_name",
            "is_registered",
            "preferences",
            "source",
            "notes",
            "memberships",
            "created_at",
            "updated_at",
        )

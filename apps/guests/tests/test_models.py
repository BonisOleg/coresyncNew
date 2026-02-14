"""Tests for guest models."""

from datetime import timedelta

import pytest
from django.utils import timezone

from apps.guests.factories import GuestFactory, GuestMembershipFactory, MembershipFactory


@pytest.mark.django_db
class TestGuest:
    def test_create_guest(self):
        guest = GuestFactory()
        assert guest.pk is not None
        assert guest.phone

    def test_full_name(self):
        guest = GuestFactory(first_name="John", last_name="Doe")
        assert guest.full_name == "John Doe"

    def test_str_with_name(self):
        guest = GuestFactory(first_name="Jane", last_name="Smith")
        assert str(guest) == "Jane Smith"

    def test_str_without_name(self):
        guest = GuestFactory(first_name="", last_name="")
        assert str(guest) == guest.phone

    def test_otp_valid(self):
        guest = GuestFactory()
        guest.otp_code = "123456"
        guest.otp_expires_at = timezone.now() + timedelta(minutes=5)
        guest.save()

        assert guest.is_otp_valid("123456")
        assert not guest.is_otp_valid("000000")

    def test_otp_expired(self):
        guest = GuestFactory()
        guest.otp_code = "123456"
        guest.otp_expires_at = timezone.now() - timedelta(minutes=1)
        guest.save()

        assert not guest.is_otp_valid("123456")


@pytest.mark.django_db
class TestMembership:
    def test_create_membership(self):
        membership = MembershipFactory()
        assert membership.pk is not None
        assert membership.is_active

    def test_guest_membership_active(self):
        gm = GuestMembershipFactory(
            start_date=timezone.now().date() - timedelta(days=1),
            end_date=timezone.now().date() + timedelta(days=30),
        )
        assert gm.is_active_now()

    def test_guest_membership_expired(self):
        gm = GuestMembershipFactory(
            start_date=timezone.now().date() - timedelta(days=60),
            end_date=timezone.now().date() - timedelta(days=1),
        )
        assert not gm.is_active_now()

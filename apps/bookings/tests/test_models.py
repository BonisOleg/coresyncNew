"""Tests for booking models."""

import pytest

from apps.bookings.factories import BookingFactory, BookingSlotFactory


@pytest.mark.django_db
class TestBookingSlot:
    def test_create_slot(self):
        slot = BookingSlotFactory()
        assert slot.pk is not None
        assert slot.is_available


@pytest.mark.django_db
class TestBooking:
    def test_create_booking(self):
        booking = BookingFactory()
        assert booking.pk is not None
        assert booking.status == "pending"
        assert booking.guest is not None

    def test_str(self):
        booking = BookingFactory()
        text = str(booking)
        assert "pending" in text

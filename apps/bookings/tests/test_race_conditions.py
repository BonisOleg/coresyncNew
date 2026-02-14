"""
Test race conditions in booking system.
Ensures concurrent bookings don't create conflicts.
"""

from datetime import date, time
from threading import Thread

import pytest
from django.test import TestCase, TransactionTestCase

from apps.bookings.models import Booking, BookingSlot
from apps.bookings.services import BookingError, create_booking_safe
from apps.guests.models import Guest


@pytest.mark.django_db
class TestBookingRaceConditions(TransactionTestCase):
    """Test concurrent booking attempts for the same slot."""

    def setUp(self):
        """Create test data."""
        # Create a slot
        self.slot = BookingSlot.objects.create(
            date=date(2026, 3, 21),
            time_start=time(18, 0),
            time_end=time(23, 0),
            is_available=True,
        )

        # Create two guests
        self.guest1 = Guest.objects.create(
            phone="+380111111111",
            first_name="Alice",
            source=Guest.Source.WEB,
        )
        self.guest2 = Guest.objects.create(
            phone="+380222222222",
            first_name="Bob",
            source=Guest.Source.VOICE,
        )

    def test_sequential_bookings_work(self):
        """Sequential bookings should work fine."""
        # First booking
        booking1 = create_booking_safe(
            guest=self.guest1,
            date_value=self.slot.date,
            time_start=self.slot.time_start,
            source=Booking.Source.WEB_CHAT,
        )
        self.assertIsNotNone(booking1)
        self.assertEqual(booking1.guest, self.guest1)

        # Second booking should fail
        with self.assertRaises(BookingError):
            create_booking_safe(
                guest=self.guest2,
                date_value=self.slot.date,
                time_start=self.slot.time_start,
                source=Booking.Source.VOICE,
            )

    def test_concurrent_bookings_prevent_double_booking(self):
        """Concurrent bookings should prevent double-booking."""
        results = {"booking1": None, "booking2": None, "error1": None, "error2": None}

        def create_booking_1():
            try:
                results["booking1"] = create_booking_safe(
                    guest=self.guest1,
                    date_value=self.slot.date,
                    time_start=self.slot.time_start,
                    source=Booking.Source.WEB_CHAT,
                )
            except BookingError as exc:
                results["error1"] = str(exc)

        def create_booking_2():
            try:
                results["booking2"] = create_booking_safe(
                    guest=self.guest2,
                    date_value=self.slot.date,
                    time_start=self.slot.time_start,
                    source=Booking.Source.VOICE,
                )
            except BookingError as exc:
                results["error2"] = str(exc)

        # Start both threads simultaneously
        thread1 = Thread(target=create_booking_1)
        thread2 = Thread(target=create_booking_2)

        thread1.start()
        thread2.start()

        thread1.join()
        thread2.join()

        # Exactly one should succeed, one should fail
        successful_bookings = sum(
            [
                1 if results["booking1"] else 0,
                1 if results["booking2"] else 0,
            ]
        )
        failed_bookings = sum(
            [
                1 if results["error1"] else 0,
                1 if results["error2"] else 0,
            ]
        )

        self.assertEqual(successful_bookings, 1, "Exactly one booking should succeed")
        self.assertEqual(failed_bookings, 1, "Exactly one booking should fail")

        # Check database state
        total_bookings = Booking.objects.filter(
            date=self.slot.date,
            time_start=self.slot.time_start,
        ).count()
        self.assertEqual(total_bookings, 1, "Only one booking should exist in database")

    def test_slot_not_found_error(self):
        """Should raise error if slot doesn't exist."""
        with self.assertRaises(BookingError) as context:
            create_booking_safe(
                guest=self.guest1,
                date_value=date(2026, 12, 31),
                time_start=time(20, 0),
            )
        self.assertIn("No booking slot found", str(context.exception))

    def test_slot_unavailable_error(self):
        """Should raise error if slot is marked unavailable."""
        # Block the slot
        self.slot.is_available = False
        self.slot.save()

        with self.assertRaises(BookingError) as context:
            create_booking_safe(
                guest=self.guest1,
                date_value=self.slot.date,
                time_start=self.slot.time_start,
            )
        self.assertIn("marked as unavailable", str(context.exception))

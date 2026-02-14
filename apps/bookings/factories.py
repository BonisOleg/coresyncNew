"""Factory Boy factories for Booking models."""

from __future__ import annotations

import factory

from apps.guests.factories import GuestFactory

from .models import Booking, BookingSlot


class BookingSlotFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BookingSlot

    date = factory.Faker("future_date")
    time_start = factory.LazyFunction(lambda: "18:00")
    time_end = factory.LazyFunction(lambda: "23:00")
    is_available = True
    max_capacity = 1


class BookingFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Booking

    guest = factory.SubFactory(GuestFactory)
    date = factory.Faker("future_date")
    time_start = factory.LazyFunction(lambda: "18:00")
    time_end = factory.LazyFunction(lambda: "23:00")
    status = Booking.Status.PENDING
    source = Booking.Source.WEB_CHAT

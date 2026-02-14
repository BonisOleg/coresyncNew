"""Factory Boy factories for Guest models."""

from __future__ import annotations

import factory

from .models import Guest, GuestMembership, Membership


class GuestFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Guest

    phone = factory.Sequence(lambda n: f"+1555000{n:04d}")
    email = factory.LazyAttribute(lambda o: f"guest{o.phone[-4:]}@example.com")
    first_name = factory.Faker("first_name")
    last_name = factory.Faker("last_name")
    is_registered = False
    source = Guest.Source.WEB


class MembershipFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Membership

    name = factory.Sequence(lambda n: f"Membership Tier {n}")
    description = factory.Faker("sentence")
    is_active = True


class GuestMembershipFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = GuestMembership

    guest = factory.SubFactory(GuestFactory)
    membership = factory.SubFactory(MembershipFactory)
    status = GuestMembership.Status.ACTIVE
    start_date = factory.Faker("date_this_year")

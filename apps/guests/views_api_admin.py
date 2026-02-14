"""
Admin API views for Flutter admin mode.
"""

from __future__ import annotations

from django.db.models import Count
from django.utils import timezone
from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAdminUser
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.atlas_calls.models import CallRecord
from apps.atlas_calls.serializers import CallRecordSerializer
from apps.bookings.models import Booking
from apps.bookings.serializers import BookingAdminSerializer

from .models import Guest
from .serializers import GuestAdminSerializer


class GuestListView(ListAPIView):
    """List all guests (admin only)."""

    permission_classes = [IsAdminUser]
    serializer_class = GuestAdminSerializer
    queryset = Guest.objects.prefetch_related("memberships__membership").all()


class BookingListView(ListAPIView):
    """List all bookings (admin only)."""

    permission_classes = [IsAdminUser]
    serializer_class = BookingAdminSerializer
    queryset = Booking.objects.select_related("guest").all()


class CallRecordListView(ListAPIView):
    """List all call records (admin only)."""

    permission_classes = [IsAdminUser]
    serializer_class = CallRecordSerializer
    queryset = CallRecord.objects.select_related("guest").all()


class DashboardView(APIView):
    """Dashboard stats for admin."""

    permission_classes = [IsAdminUser]

    def get(self, request: Request) -> Response:
        today = timezone.now().date()
        return Response(
            {
                "total_guests": Guest.objects.count(),
                "registered_guests": Guest.objects.filter(is_registered=True).count(),
                "bookings_today": Booking.objects.filter(date=today).count(),
                "bookings_pending": Booking.objects.filter(status=Booking.Status.PENDING).count(),
                "total_calls": CallRecord.objects.count(),
                "calls_today": CallRecord.objects.filter(created_at__date=today).count(),
                "bookings_by_source": dict(
                    Booking.objects.values_list("source")
                    .annotate(count=Count("id"))
                    .values_list("source", "count")
                ),
            }
        )

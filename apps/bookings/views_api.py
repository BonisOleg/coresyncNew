"""
Booking REST API views.
"""

from __future__ import annotations

from rest_framework import status
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response

from apps.guests.utils import get_guest_from_token

from .models import Booking
from .serializers import BookingCreateSerializer, BookingSerializer
from .utils import sync_booking_to_calcom


class BookingListCreateView(ListCreateAPIView):
    """List guest's bookings or create a new one."""

    permission_classes = [IsAuthenticated]
    serializer_class = BookingSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Booking.objects.none()
        return Booking.objects.filter(guest=guest)

    def create(self, request: Request, *args, **kwargs) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = BookingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        booking = Booking.objects.create(
            guest=guest,
            source=Booking.Source.FLUTTER,
            **serializer.validated_data,
        )

        # Sync to Cal.com (non-blocking)
        sync_booking_to_calcom(booking)

        return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)


class BookingDetailView(RetrieveUpdateAPIView):
    """Retrieve or update a specific booking."""

    permission_classes = [IsAuthenticated]
    serializer_class = BookingSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Booking.objects.none()
        return Booking.objects.filter(guest=guest)

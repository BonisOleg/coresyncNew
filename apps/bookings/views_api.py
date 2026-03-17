"""
Booking REST API views — CRUD, slots, check-in, session timer.
"""

from __future__ import annotations

from django.utils import timezone

from rest_framework import status
from rest_framework.generics import ListAPIView, ListCreateAPIView, RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.guests.utils import get_guest_from_token

from .models import Booking, BookingSlot, CheckIn
from .serializers import (
    BookingCreateSerializer,
    BookingSerializer,
    BookingSlotSerializer,
    CheckInSerializer,
    SessionTimerSerializer,
)
from .utils import sync_booking_to_calcom


class BookingListCreateView(ListCreateAPIView):
    """List guest's bookings or create a new one."""

    permission_classes = [IsAuthenticated]
    serializer_class = BookingSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Booking.objects.none()
        return Booking.objects.filter(guest=guest).select_related("checkin")

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
        return Booking.objects.filter(guest=guest).select_related("checkin")


# ---------------------------------------------------------------------------
# Slot listing
# ---------------------------------------------------------------------------


class SlotListView(ListAPIView):
    """List available booking slots, filterable by date."""

    permission_classes = [IsAuthenticated]
    serializer_class = BookingSlotSerializer

    def get_queryset(self):
        qs = BookingSlot.objects.filter(is_available=True, date__gte=timezone.now().date())
        date_filter = self.request.query_params.get("date")
        if date_filter:
            qs = qs.filter(date=date_filter)
        return qs


# ---------------------------------------------------------------------------
# Check-in / check-out
# ---------------------------------------------------------------------------


class CheckInView(APIView):
    """Manual guest check-in for a booking."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request, pk) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            booking = Booking.objects.get(pk=pk, guest=guest)
        except Booking.DoesNotExist:
            return Response({"detail": "Booking not found."}, status=status.HTTP_404_NOT_FOUND)

        if booking.status not in (Booking.Status.PENDING, Booking.Status.CONFIRMED):
            return Response(
                {"detail": f"Cannot check in — booking is {booking.status}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        today = timezone.now().date()
        if booking.date != today:
            return Response(
                {"detail": "Check-in is only available on the booking date."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if hasattr(booking, "checkin") and booking.checkin.status == CheckIn.Status.CHECKED_IN:
            return Response(
                {"detail": "Already checked in."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        checkin, created = CheckIn.objects.get_or_create(
            booking=booking,
            defaults={"guest": guest, "status": CheckIn.Status.CHECKED_IN},
        )
        if not created:
            checkin.status = CheckIn.Status.CHECKED_IN
            checkin.checked_out_at = None
            checkin.save(update_fields=["status", "checked_out_at"])

        if booking.status == Booking.Status.PENDING:
            booking.status = Booking.Status.CONFIRMED
            booking.save(update_fields=["status"])

        return Response(CheckInSerializer(checkin).data, status=status.HTTP_201_CREATED)


class CheckOutView(APIView):
    """Manual guest check-out for a booking."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request, pk) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            booking = Booking.objects.select_related("checkin").get(pk=pk, guest=guest)
        except Booking.DoesNotExist:
            return Response({"detail": "Booking not found."}, status=status.HTTP_404_NOT_FOUND)

        if not hasattr(booking, "checkin") or booking.checkin.status != CheckIn.Status.CHECKED_IN:
            return Response({"detail": "Not checked in."}, status=status.HTTP_400_BAD_REQUEST)

        checkin = booking.checkin
        checkin.status = CheckIn.Status.CHECKED_OUT
        checkin.checked_out_at = timezone.now()
        checkin.save(update_fields=["status", "checked_out_at"])

        booking.status = Booking.Status.COMPLETED
        booking.save(update_fields=["status"])

        return Response(CheckInSerializer(checkin).data)


# ---------------------------------------------------------------------------
# Active booking & session timer
# ---------------------------------------------------------------------------


class ActiveBookingView(APIView):
    """Get the guest's current active booking (checked in, not checked out)."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        checkin = (
            CheckIn.objects
            .filter(guest=guest, status=CheckIn.Status.CHECKED_IN)
            .select_related("booking")
            .first()
        )
        if not checkin:
            return Response({"detail": "No active booking."}, status=status.HTTP_404_NOT_FOUND)

        return Response(CheckInSerializer(checkin).data)


class SessionTimerView(APIView):
    """Get session timer info for the currently active booking."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        checkin = (
            CheckIn.objects
            .filter(guest=guest, status=CheckIn.Status.CHECKED_IN)
            .select_related("booking")
            .first()
        )
        if not checkin:
            return Response({"detail": "No active session."}, status=status.HTTP_404_NOT_FOUND)

        booking = checkin.booking
        now = timezone.now()
        remaining = max(0, int((booking.session_end_datetime - now).total_seconds()))

        data = SessionTimerSerializer({
            "booking_id": booking.id,
            "date": booking.date,
            "time_start": booking.time_start,
            "time_end": booking.time_end,
            "checked_in_at": checkin.checked_in_at,
            "total_seconds": booking.total_seconds,
            "remaining_seconds": remaining,
        }).data

        return Response(data)

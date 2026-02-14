"""
Guest profile API views.
"""

from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Guest
from .serializers import GuestProfileSerializer, GuestProfileUpdateSerializer
from .utils import get_guest_from_token


class GuestProfileView(APIView):
    """Retrieve or update the authenticated guest's profile."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = GuestProfileSerializer(guest)
        return Response(serializer.data)

    def patch(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = GuestProfileUpdateSerializer(guest, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(GuestProfileSerializer(guest).data)

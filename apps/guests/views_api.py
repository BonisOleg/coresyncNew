"""
Guest profile API views.
"""

from __future__ import annotations

import logging

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Guest
from .serializers import GuestProfileSerializer, GuestProfileUpdateSerializer
from .utils import get_guest_from_token

logger = logging.getLogger(__name__)


class GuestProfileView(APIView):
    """Retrieve, update, or delete the authenticated guest's profile."""

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

    def delete(self, request: Request) -> Response:
        """Delete guest account and all associated data (App Store / Play Store requirement)."""
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        guest_id = guest.id
        guest.delete()
        logger.info("Guest account deleted: %s", guest_id)
        return Response({"detail": "Account deleted."}, status=status.HTTP_204_NO_CONTENT)

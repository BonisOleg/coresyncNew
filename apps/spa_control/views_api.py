"""
SPA device control API views.
"""

from __future__ import annotations

from rest_framework import status
from rest_framework.generics import ListAPIView, ListCreateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.guests.utils import get_guest_from_token

from .models import Device, GuestPreset
from .serializers import DeviceControlSerializer, DeviceSerializer, GuestPresetSerializer


class DeviceListView(ListAPIView):
    """List all available SPA devices."""

    permission_classes = [IsAuthenticated]
    serializer_class = DeviceSerializer
    queryset = Device.objects.select_related("device_type").all()


class DeviceControlView(APIView):
    """Send a control command to a specific device."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request, pk) -> Response:
        try:
            device = Device.objects.get(pk=pk)
        except Device.DoesNotExist:
            return Response({"detail": "Device not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = DeviceControlSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        desired_state = serializer.validated_data["state"]

        # Update device state in DB (actual hardware control is a future adapter)
        device.current_state.update(desired_state)
        device.save(update_fields=["current_state"])

        return Response(DeviceSerializer(device).data)


class PresetListCreateView(ListCreateAPIView):
    """List or create guest device presets."""

    permission_classes = [IsAuthenticated]
    serializer_class = GuestPresetSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return GuestPreset.objects.none()
        return GuestPreset.objects.filter(guest=guest)

    def perform_create(self, serializer):
        guest = get_guest_from_token(self.request)
        serializer.save(guest=guest)

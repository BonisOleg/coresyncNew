"""
SPA device control, scenes, and scent API views.
"""

from __future__ import annotations

from rest_framework import status
from rest_framework.generics import ListAPIView, ListCreateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.guests.utils import get_guest_from_token

from .models import (
    ActiveRoomScene,
    ActiveScent,
    Device,
    GuestPreset,
    Scene,
    SceneMusic,
    ScentProfile,
)
from .serializers import (
    ActiveRoomSceneSerializer,
    ActiveScentSerializer,
    DeviceControlSerializer,
    DeviceSerializer,
    GuestPresetSerializer,
    SceneActivateSerializer,
    SceneSerializer,
    ScentActivateSerializer,
    ScentProfileSerializer,
    ScentUpdateIntensitySerializer,
)


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


# ---------------------------------------------------------------------------
# Scenes
# ---------------------------------------------------------------------------


class SceneListView(ListAPIView):
    """List all available room scenes with their music tracks."""

    permission_classes = [IsAuthenticated]
    serializer_class = SceneSerializer
    queryset = Scene.objects.filter(is_active=True).prefetch_related("tracks")


class SceneActivateView(APIView):
    """Activate a scene for the guest's room."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = SceneActivateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            scene = Scene.objects.get(pk=serializer.validated_data["scene_id"], is_active=True)
        except Scene.DoesNotExist:
            return Response({"detail": "Scene not found."}, status=status.HTTP_404_NOT_FOUND)

        ActiveRoomScene.objects.filter(guest=guest).delete()

        first_track = scene.tracks.first() if serializer.validated_data["music_enabled"] else None

        active = ActiveRoomScene.objects.create(
            guest=guest,
            scene=scene,
            music_enabled=serializer.validated_data["music_enabled"],
            current_track=first_track,
        )
        return Response(ActiveRoomSceneSerializer(active).data, status=status.HTTP_201_CREATED)


class ActiveSceneView(APIView):
    """Get or deactivate the currently active scene."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        active = ActiveRoomScene.objects.filter(guest=guest).select_related(
            "scene", "current_track",
        ).first()
        if not active:
            return Response({"detail": "No active scene."}, status=status.HTTP_404_NOT_FOUND)

        return Response(ActiveRoomSceneSerializer(active).data)

    def delete(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        deleted, _ = ActiveRoomScene.objects.filter(guest=guest).delete()
        if not deleted:
            return Response({"detail": "No active scene."}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Scent
# ---------------------------------------------------------------------------


class ScentProfileListView(ListAPIView):
    """List all available scent profiles."""

    permission_classes = [IsAuthenticated]
    serializer_class = ScentProfileSerializer
    queryset = ScentProfile.objects.filter(is_active=True)


class ScentActivateView(APIView):
    """Activate a scent profile for the guest's room."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = ScentActivateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            profile = ScentProfile.objects.get(
                pk=serializer.validated_data["scent_profile_id"], is_active=True,
            )
        except ScentProfile.DoesNotExist:
            return Response({"detail": "Scent profile not found."}, status=status.HTTP_404_NOT_FOUND)

        ActiveScent.objects.filter(guest=guest).delete()

        active = ActiveScent.objects.create(
            guest=guest,
            scent_profile=profile,
            intensity=serializer.validated_data["intensity"],
        )
        return Response(ActiveScentSerializer(active).data, status=status.HTTP_201_CREATED)


class ActiveScentView(APIView):
    """Get, update intensity, or deactivate the currently active scent."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        active = ActiveScent.objects.filter(guest=guest).select_related("scent_profile").first()
        if not active:
            return Response({"detail": "No active scent."}, status=status.HTTP_404_NOT_FOUND)
        return Response(ActiveScentSerializer(active).data)

    def patch(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        active = ActiveScent.objects.filter(guest=guest).select_related("scent_profile").first()
        if not active:
            return Response({"detail": "No active scent."}, status=status.HTTP_404_NOT_FOUND)

        serializer = ScentUpdateIntensitySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        active.intensity = serializer.validated_data["intensity"]
        active.save(update_fields=["intensity"])
        return Response(ActiveScentSerializer(active).data)

    def delete(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        deleted, _ = ActiveScent.objects.filter(guest=guest).delete()
        if not deleted:
            return Response({"detail": "No active scent."}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)

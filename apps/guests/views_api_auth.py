"""
Authentication API views — phone + OTP login, JWT tokens.
"""

from __future__ import annotations

import random
import string
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Guest
from .serializers import LoginSerializer, VerifyOTPSerializer


def _generate_otp() -> str:
    """Generate a 6-digit OTP code."""
    return "".join(random.choices(string.digits, k=6))


class LoginView(APIView):
    """Send OTP to the guest's phone number (via email for now)."""

    permission_classes = [AllowAny]
    throttle_scope = "anon"

    def post(self, request: Request) -> Response:
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"]

        guest, _ = Guest.objects.get_or_create(
            phone=phone,
            defaults={"source": Guest.Source.FLUTTER},
        )

        otp = _generate_otp()
        guest.otp_code = otp
        guest.otp_expires_at = timezone.now() + timedelta(minutes=5)
        guest.save(update_fields=["otp_code", "otp_expires_at"])

        # Send OTP via email (to guest's email if available, or log to console)
        if guest.email:
            send_mail(
                subject="CoreSync Private — Your verification code",
                message=f"Your verification code is: {otp}",
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[guest.email],
                fail_silently=True,
            )

        return Response(
            {"detail": "Verification code sent.", "phone": phone},
            status=status.HTTP_200_OK,
        )


class VerifyOTPView(APIView):
    """Verify OTP and return JWT tokens."""

    permission_classes = [AllowAny]
    throttle_scope = "anon"

    def post(self, request: Request) -> Response:
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone = serializer.validated_data["phone"]
        otp = serializer.validated_data["otp"]

        try:
            guest = Guest.objects.get(phone=phone)
        except Guest.DoesNotExist:
            return Response(
                {"detail": "Guest not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not guest.is_otp_valid(otp):
            return Response(
                {"detail": "Invalid or expired code."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Clear OTP
        guest.otp_code = ""
        guest.otp_expires_at = None
        guest.save(update_fields=["otp_code", "otp_expires_at"])

        # Generate JWT tokens using guest ID as claim
        refresh = RefreshToken()
        refresh["guest_id"] = str(guest.id)
        refresh["phone"] = guest.phone

        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "guest_id": str(guest.id),
                "is_registered": guest.is_registered,
            },
            status=status.HTTP_200_OK,
        )


class RefreshTokenView(APIView):
    """Refresh JWT access token."""

    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response(
                {"detail": "Refresh token required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            refresh = RefreshToken(refresh_token)
            return Response(
                {
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                },
                status=status.HTTP_200_OK,
            )
        except Exception:
            return Response(
                {"detail": "Invalid refresh token."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

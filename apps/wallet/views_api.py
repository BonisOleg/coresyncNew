"""Wallet REST API views — balance, payment methods, top-up, transactions."""

from __future__ import annotations

from decimal import Decimal

import stripe
from django.conf import settings
from django.db import transaction as db_transaction

from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.guests.utils import get_guest_from_token

from .models import PaymentMethod, Transaction, WalletBalance
from .serializers import (
    PaymentMethodSerializer,
    SavePaymentMethodSerializer,
    SetupIntentSerializer,
    TopUpSerializer,
    TransactionSerializer,
    WalletBalanceSerializer,
    WalletPaySerializer,
)
from .utils import get_or_create_stripe_customer

stripe.api_key = settings.STRIPE_SECRET_KEY


class WalletOverviewView(APIView):
    """Get wallet balance and default payment method."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        wallet, _ = WalletBalance.objects.get_or_create(guest=guest)
        return Response(WalletBalanceSerializer(wallet).data)


class SetupIntentView(APIView):
    """Create a Stripe SetupIntent for saving a payment method."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        customer_id = get_or_create_stripe_customer(guest)

        setup_intent = stripe.SetupIntent.create(
            customer=customer_id,
            payment_method_types=["card"],
        )

        return Response(SetupIntentSerializer({
            "client_secret": setup_intent.client_secret,
            "customer_id": customer_id,
        }).data)


class PaymentMethodListView(ListAPIView):
    """List saved payment methods."""

    permission_classes = [IsAuthenticated]
    serializer_class = PaymentMethodSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return PaymentMethod.objects.none()
        return PaymentMethod.objects.filter(guest=guest)


class SavePaymentMethodView(APIView):
    """Save a payment method after successful SetupIntent confirmation."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = SavePaymentMethodSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        pm_id = serializer.validated_data["stripe_payment_method_id"]

        try:
            stripe_pm = stripe.PaymentMethod.retrieve(pm_id)
        except stripe.error.StripeError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        is_first = not PaymentMethod.objects.filter(guest=guest).exists()

        pm = PaymentMethod.objects.create(
            guest=guest,
            stripe_payment_method_id=pm_id,
            card_brand=getattr(stripe_pm.card, "brand", ""),
            card_last4=getattr(stripe_pm.card, "last4", ""),
            type=PaymentMethod.Type.CARD,
            is_default=is_first,
        )

        return Response(PaymentMethodSerializer(pm).data, status=status.HTTP_201_CREATED)


class DeletePaymentMethodView(APIView):
    """Remove a saved payment method."""

    permission_classes = [IsAuthenticated]

    def delete(self, request: Request, pk) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            pm = PaymentMethod.objects.get(pk=pk, guest=guest)
        except PaymentMethod.DoesNotExist:
            return Response({"detail": "Payment method not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            stripe.PaymentMethod.detach(pm.stripe_payment_method_id)
        except stripe.error.StripeError:
            pass

        was_default = pm.is_default
        pm.delete()

        if was_default:
            next_pm = PaymentMethod.objects.filter(guest=guest).first()
            if next_pm:
                next_pm.is_default = True
                next_pm.save(update_fields=["is_default"])

        return Response(status=status.HTTP_204_NO_CONTENT)


class TopUpView(APIView):
    """Top up wallet balance using a saved payment method."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = TopUpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        customer_id = get_or_create_stripe_customer(guest)

        try:
            intent = stripe.PaymentIntent.create(
                amount=int(data["amount"] * 100),
                currency="usd",
                customer=customer_id,
                payment_method=data["payment_method_id"],
                confirm=True,
                automatic_payment_methods={"enabled": True, "allow_redirects": "never"},
                metadata={"guest_id": str(guest.id), "type": "wallet_top_up"},
            )
        except stripe.error.StripeError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        if intent.status != "succeeded":
            return Response(
                {"detail": f"Payment not completed: {intent.status}", "client_secret": intent.client_secret},
                status=status.HTTP_402_PAYMENT_REQUIRED,
            )

        with db_transaction.atomic():
            wallet, _ = WalletBalance.objects.select_for_update().get_or_create(guest=guest)
            wallet.balance += Decimal(str(data["amount"]))
            wallet.save(update_fields=["balance", "updated_at"])

            Transaction.objects.create(
                guest=guest,
                type=Transaction.Type.TOP_UP,
                amount=data["amount"],
                balance_after=wallet.balance,
                description=f"Wallet top-up ${data['amount']}",
                stripe_payment_intent_id=intent.id,
            )

        return Response(WalletBalanceSerializer(wallet).data)


class TransactionListView(ListAPIView):
    """List wallet transactions."""

    permission_classes = [IsAuthenticated]
    serializer_class = TransactionSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Transaction.objects.none()
        return Transaction.objects.filter(guest=guest)


class WalletPayView(APIView):
    """Pay from wallet balance."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = WalletPaySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        amount = Decimal(str(data["amount"]))

        with db_transaction.atomic():
            wallet, _ = WalletBalance.objects.select_for_update().get_or_create(guest=guest)

            if wallet.balance < amount:
                return Response(
                    {"detail": "Insufficient balance.", "balance": str(wallet.balance)},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            wallet.balance -= amount
            wallet.save(update_fields=["balance", "updated_at"])

            Transaction.objects.create(
                guest=guest,
                type=Transaction.Type.PAYMENT,
                amount=-amount,
                balance_after=wallet.balance,
                description=data.get("description", ""),
                order_id=data.get("order_id"),
                booking_id=data.get("booking_id"),
            )

        return Response(WalletBalanceSerializer(wallet).data)

"""Orders REST API views."""

from __future__ import annotations

from rest_framework import status
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.bookings.models import Booking
from apps.guests.utils import get_guest_from_token

from .models import Order, OrderItem, Product
from .serializers import OrderCreateSerializer, OrderSerializer, ProductSerializer


class ProductListView(ListAPIView):
    """List available products, filterable by category."""

    permission_classes = [IsAuthenticated]
    serializer_class = ProductSerializer

    def get_queryset(self):
        qs = Product.objects.filter(is_available=True)
        category = self.request.query_params.get("category")
        if category:
            qs = qs.filter(category=category)
        return qs


class OrderListView(ListAPIView):
    """List guest's orders."""

    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Order.objects.none()
        return Order.objects.filter(guest=guest).prefetch_related("items__product")


class OrderDetailView(RetrieveAPIView):
    """Get order detail."""

    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer

    def get_queryset(self):
        guest = get_guest_from_token(self.request)
        if not guest:
            return Order.objects.none()
        return Order.objects.filter(guest=guest).prefetch_related("items__product")


class OrderCreateView(APIView):
    """Create a new order with line items."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        guest = get_guest_from_token(request)
        if not guest:
            return Response({"detail": "Guest not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        booking = None
        if data.get("booking_id"):
            try:
                booking = Booking.objects.get(pk=data["booking_id"], guest=guest)
            except Booking.DoesNotExist:
                return Response({"detail": "Booking not found."}, status=status.HTTP_404_NOT_FOUND)

        product_ids = [item["product_id"] for item in data["items"]]
        products = {p.id: p for p in Product.objects.filter(id__in=product_ids, is_available=True)}

        missing = set(product_ids) - set(products.keys())
        if missing:
            return Response(
                {"detail": f"Products not found or unavailable: {missing}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        order = Order.objects.create(
            guest=guest,
            booking=booking,
            message=data.get("message", ""),
        )

        order_items = []
        for item_data in data["items"]:
            product = products[item_data["product_id"]]
            order_items.append(OrderItem(
                order=order,
                product=product,
                quantity=item_data["quantity"],
                unit_price=product.price,
            ))

        OrderItem.objects.bulk_create(order_items)
        order.recalculate_total()

        return Response(
            OrderSerializer(order).data,
            status=status.HTTP_201_CREATED,
        )

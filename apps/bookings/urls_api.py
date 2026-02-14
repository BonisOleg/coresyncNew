"""Booking REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "bookings_api"

urlpatterns = [
    path("", views_api.BookingListCreateView.as_view(), name="list_create"),
    path("<uuid:pk>/", views_api.BookingDetailView.as_view(), name="detail"),
]

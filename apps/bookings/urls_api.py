"""Booking REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "bookings_api"

urlpatterns = [
    path("", views_api.BookingListCreateView.as_view(), name="list_create"),
    path("slots/", views_api.SlotListView.as_view(), name="slots"),
    path("active/", views_api.ActiveBookingView.as_view(), name="active"),
    path("session/", views_api.SessionTimerView.as_view(), name="session"),
    path("<uuid:pk>/", views_api.BookingDetailView.as_view(), name="detail"),
    path("<uuid:pk>/checkin/", views_api.CheckInView.as_view(), name="checkin"),
    path("<uuid:pk>/checkout/", views_api.CheckOutView.as_view(), name="checkout"),
]

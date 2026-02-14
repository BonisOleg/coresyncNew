"""Admin API endpoints for Flutter admin mode."""

from django.urls import path

from . import views_api_admin

app_name = "admin_api"

urlpatterns = [
    path("guests/", views_api_admin.GuestListView.as_view(), name="guests"),
    path("bookings/", views_api_admin.BookingListView.as_view(), name="bookings"),
    path("calls/", views_api_admin.CallRecordListView.as_view(), name="calls"),
    path("dashboard/", views_api_admin.DashboardView.as_view(), name="dashboard"),
]

"""Guest profile API endpoints."""

from django.urls import path

from . import views_api

app_name = "guest_api"

urlpatterns = [
    path("profile/", views_api.GuestProfileView.as_view(), name="profile"),
]

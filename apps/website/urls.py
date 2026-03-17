"""Website URL configuration — the single room entry point."""

from django.urls import path

from . import views

app_name = "website"

urlpatterns = [
    path("", views.room_view, name="room"),
    path("privacy/", views.privacy_policy, name="privacy"),
    path("support/", views.support_page, name="support"),
]

"""Website URL configuration — the single room entry point."""

from django.urls import path

from . import views

app_name = "website"

urlpatterns = [
    path("", views.room_view, name="room"),
    path("privacy/", views.privacy_policy, name="privacy"),
    path("terms/", views.terms_of_service, name="terms"),
    path("cancellation-policy/", views.cancellation_policy, name="cancellation"),
    path("support/", views.support_page, name="support"),
]

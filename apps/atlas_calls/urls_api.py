"""Atlas.AI webhook and action endpoints."""

from django.urls import path

from . import views_api

app_name = "atlas_api"

urlpatterns = [
    path("webhook/", views_api.atlas_webhook, name="webhook"),
    # Atlas Actions - called by AI during conversations
    path("actions/check-availability/", views_api.check_availability_action, name="check_availability"),
]

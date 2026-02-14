"""Concierge HTMX endpoints for web chat."""

from django.urls import path

from . import views

app_name = "concierge"

urlpatterns = [
    path("panel/", views.concierge_panel, name="panel"),
    path("message/", views.concierge_message, name="message"),
]

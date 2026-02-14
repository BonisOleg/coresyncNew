"""Cal.com webhook endpoint."""

from django.urls import path

from . import views_calcom

app_name = "calcom"

urlpatterns = [
    path("webhook/", views_calcom.calcom_webhook, name="webhook"),
]

"""REST API endpoints for concierge (Flutter)."""

from django.urls import path

from . import views_api

app_name = "concierge_api"

urlpatterns = [
    path("message/", views_api.ConciergeMessageAPIView.as_view(), name="message"),
    path("history/", views_api.ConversationHistoryAPIView.as_view(), name="history"),
]

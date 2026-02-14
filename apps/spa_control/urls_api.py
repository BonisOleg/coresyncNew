"""SPA control REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "spa_api"

urlpatterns = [
    path("devices/", views_api.DeviceListView.as_view(), name="devices"),
    path("devices/<uuid:pk>/control/", views_api.DeviceControlView.as_view(), name="device_control"),
    path("presets/", views_api.PresetListCreateView.as_view(), name="presets"),
]

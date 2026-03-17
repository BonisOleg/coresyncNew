"""SPA control REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "spa_api"

urlpatterns = [
    # Devices
    path("devices/", views_api.DeviceListView.as_view(), name="devices"),
    path("devices/<uuid:pk>/control/", views_api.DeviceControlView.as_view(), name="device_control"),
    path("presets/", views_api.PresetListCreateView.as_view(), name="presets"),
    # Scenes
    path("scenes/", views_api.SceneListView.as_view(), name="scenes"),
    path("scenes/activate/", views_api.SceneActivateView.as_view(), name="scene_activate"),
    path("scenes/active/", views_api.ActiveSceneView.as_view(), name="scene_active"),
    # Scent
    path("scents/", views_api.ScentProfileListView.as_view(), name="scents"),
    path("scents/activate/", views_api.ScentActivateView.as_view(), name="scent_activate"),
    path("scents/active/", views_api.ActiveScentView.as_view(), name="scent_active"),
]

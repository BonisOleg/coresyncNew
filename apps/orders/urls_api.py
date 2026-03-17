"""Orders REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "orders_api"

urlpatterns = [
    path("products/", views_api.ProductListView.as_view(), name="products"),
    path("", views_api.OrderListView.as_view(), name="list"),
    path("create/", views_api.OrderCreateView.as_view(), name="create"),
    path("<uuid:pk>/", views_api.OrderDetailView.as_view(), name="detail"),
]

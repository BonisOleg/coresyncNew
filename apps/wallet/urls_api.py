"""Wallet REST API endpoints."""

from django.urls import path

from . import views_api

app_name = "wallet_api"

urlpatterns = [
    path("", views_api.WalletOverviewView.as_view(), name="overview"),
    path("setup-intent/", views_api.SetupIntentView.as_view(), name="setup_intent"),
    path("payment-methods/", views_api.PaymentMethodListView.as_view(), name="payment_methods"),
    path("payment-methods/save/", views_api.SavePaymentMethodView.as_view(), name="save_payment_method"),
    path("payment-methods/<uuid:pk>/", views_api.DeletePaymentMethodView.as_view(), name="delete_payment_method"),
    path("top-up/", views_api.TopUpView.as_view(), name="top_up"),
    path("transactions/", views_api.TransactionListView.as_view(), name="transactions"),
    path("pay/", views_api.WalletPayView.as_view(), name="pay"),
]

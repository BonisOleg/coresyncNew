"""Authentication API endpoints (phone + OTP)."""

from django.urls import path

from . import views_api_auth

app_name = "auth_api"

urlpatterns = [
    path("login/", views_api_auth.LoginView.as_view(), name="login"),
    path("verify/", views_api_auth.VerifyOTPView.as_view(), name="verify"),
    path("refresh/", views_api_auth.RefreshTokenView.as_view(), name="refresh"),
]

"""
Root URL configuration for CoreSync Private.
"""

from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # Django admin
    path("admin/", admin.site.urls),
    # Website (single room — the main entry point)
    path("", include("apps.website.urls")),
    # AI Concierge (HTMX endpoints for web chat)
    path("concierge/", include("apps.concierge.urls")),
    # Explore panels (HTMX partials)
    path("explore/", include("apps.website.urls_explore")),
    # REST API (Flutter + external integrations)
    path("api/auth/", include("apps.guests.urls_api_auth")),
    path("api/guest/", include("apps.guests.urls_api")),
    path("api/bookings/", include("apps.bookings.urls_api")),
    path("api/concierge/", include("apps.concierge.urls_api")),
    path("api/atlas/", include("apps.atlas_calls.urls_api")),
    path("api/calcom/", include("apps.bookings.urls_calcom")),
    path("api/spa/", include("apps.spa_control.urls_api")),
    path("api/orders/", include("apps.orders.urls_api")),
    path("api/wallet/", include("apps.wallet.urls_api")),
    path("api/admin/", include("apps.guests.urls_api_admin")),
    # Healthcheck
    path("healthz/", include("apps.website.urls_health")),
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Admin site customization
admin.site.site_header = "CoreSync Private"
admin.site.site_title = "CoreSync Admin"
admin.site.index_title = "Dashboard"

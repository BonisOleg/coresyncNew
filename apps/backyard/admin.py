from django.contrib import admin

from .models import WaitlistEntry


@admin.register(WaitlistEntry)
class WaitlistEntryAdmin(admin.ModelAdmin):
    list_display = ("name", "email", "phone", "source", "guest", "created_at")
    list_filter = ("source", "created_at")
    search_fields = ("name", "email", "phone")
    readonly_fields = ("id", "created_at")

from django.contrib import admin

from .models import Booking, BookingSlot


@admin.register(BookingSlot)
class BookingSlotAdmin(admin.ModelAdmin):
    list_display = ("date", "time_start", "time_end", "is_available", "max_capacity")
    list_filter = ("is_available", "date")
    date_hierarchy = "date"


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = (
        "guest",
        "date",
        "time_start",
        "time_end",
        "status",
        "source",
        "created_at",
    )
    list_filter = ("status", "source", "date")
    search_fields = ("guest__phone", "guest__email", "guest__first_name", "notes")
    readonly_fields = ("id", "created_at", "updated_at")
    date_hierarchy = "date"
    fieldsets = (
        (None, {"fields": ("id", "guest", "slot", "date", "time_start", "time_end")}),
        ("Status", {"fields": ("status", "source")}),
        ("Details", {"fields": ("preferences", "notes")}),
        (
            "Cal.com",
            {
                "fields": ("calcom_event_id", "calcom_booking_uid"),
                "classes": ("collapse",),
            },
        ),
        ("Timestamps", {"fields": ("created_at", "updated_at")}),
    )

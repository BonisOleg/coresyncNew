from django.contrib import admin

from .models import Guest, GuestMembership, Membership


class GuestMembershipInline(admin.TabularInline):
    model = GuestMembership
    extra = 0
    readonly_fields = ("created_at",)


@admin.register(Guest)
class GuestAdmin(admin.ModelAdmin):
    list_display = (
        "full_name",
        "phone",
        "email",
        "is_registered",
        "source",
        "created_at",
    )
    list_filter = ("is_registered", "source", "created_at")
    search_fields = ("phone", "email", "first_name", "last_name")
    readonly_fields = ("id", "created_at", "updated_at")
    inlines = [GuestMembershipInline]
    fieldsets = (
        (None, {"fields": ("id", "phone", "email", "first_name", "last_name")}),
        ("Registration", {"fields": ("is_registered", "source", "face_id_token")}),
        ("Preferences", {"fields": ("preferences", "notes")}),
        ("OTP", {"fields": ("otp_code", "otp_expires_at"), "classes": ("collapse",)}),
        ("Timestamps", {"fields": ("created_at", "updated_at")}),
    )


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(GuestMembership)
class GuestMembershipAdmin(admin.ModelAdmin):
    list_display = ("guest", "membership", "status", "start_date", "end_date")
    list_filter = ("status", "membership")
    search_fields = ("guest__phone", "guest__email", "guest__first_name")
    readonly_fields = ("created_at",)

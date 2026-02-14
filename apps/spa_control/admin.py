from django.contrib import admin

from .models import Device, DeviceType, GuestPreset


@admin.register(DeviceType)
class DeviceTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "capabilities")
    search_fields = ("name",)


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ("name", "device_type", "room", "is_online")
    list_filter = ("device_type", "is_online", "room")
    search_fields = ("name", "room")


@admin.register(GuestPreset)
class GuestPresetAdmin(admin.ModelAdmin):
    list_display = ("guest", "name", "created_at")
    search_fields = ("guest__phone", "guest__first_name", "name")

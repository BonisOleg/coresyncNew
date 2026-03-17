from django.contrib import admin

from .models import (
    ActiveRoomScene,
    ActiveScent,
    Device,
    DeviceType,
    GuestPreset,
    Scene,
    SceneMusic,
    ScentProfile,
)


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


class SceneMusicInline(admin.TabularInline):
    model = SceneMusic
    extra = 1
    fields = ("title", "artist", "audio_url", "duration_seconds", "order")


@admin.register(Scene)
class SceneAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "is_active", "order")
    list_filter = ("category", "is_active")
    search_fields = ("name",)
    inlines = [SceneMusicInline]


@admin.register(ScentProfile)
class ScentProfileAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "intensity_default", "is_active", "order")
    list_filter = ("category", "is_active")
    search_fields = ("name",)


@admin.register(ActiveRoomScene)
class ActiveRoomSceneAdmin(admin.ModelAdmin):
    list_display = ("guest", "scene", "music_enabled", "activated_at")
    list_filter = ("music_enabled",)
    raw_id_fields = ("guest", "booking", "scene", "current_track")


@admin.register(ActiveScent)
class ActiveScentAdmin(admin.ModelAdmin):
    list_display = ("guest", "scent_profile", "intensity", "activated_at")
    raw_id_fields = ("guest", "booking", "scent_profile")

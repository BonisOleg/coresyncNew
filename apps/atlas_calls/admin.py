from django.contrib import admin

from .models import CallRecord


@admin.register(CallRecord)
class CallRecordAdmin(admin.ModelAdmin):
    list_display = (
        "atlas_call_id_short",
        "phone_number",
        "guest",
        "direction",
        "status",
        "outcome",
        "duration_seconds",
        "created_at",
    )
    list_filter = ("status", "direction", "outcome", "created_at")
    search_fields = ("phone_number", "atlas_call_id", "guest__phone", "transcript")
    readonly_fields = ("id", "created_at")

    @admin.display(description="Call ID")
    def atlas_call_id_short(self, obj: CallRecord) -> str:
        return obj.atlas_call_id[:12] + "…"

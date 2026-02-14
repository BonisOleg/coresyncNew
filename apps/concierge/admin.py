from django.contrib import admin

from .models import ConciergeImage, Conversation, Message


class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    readonly_fields = ("id", "role", "content", "metadata", "created_at")
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ("session_id_short", "guest", "channel", "status", "created_at", "updated_at")
    list_filter = ("status", "channel", "created_at")
    search_fields = ("session_id", "guest__phone", "guest__email")
    readonly_fields = ("id", "session_id", "created_at", "updated_at")
    inlines = [MessageInline]

    @admin.display(description="Session")
    def session_id_short(self, obj: Conversation) -> str:
        return obj.session_id[:12] + "…"


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ("role", "content_preview", "conversation", "created_at")
    list_filter = ("role", "created_at")
    readonly_fields = ("id", "created_at")

    @admin.display(description="Content")
    def content_preview(self, obj: Message) -> str:
        return obj.content[:80] + "…" if len(obj.content) > 80 else obj.content


@admin.register(ConciergeImage)
class ConciergeImageAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "show_after_intent", "order")
    list_filter = ("category", "show_after_intent")
    list_editable = ("order",)

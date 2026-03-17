from django.contrib import admin

from .models import Order, OrderItem, Product


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "price", "is_available", "order")
    list_filter = ("category", "is_available")
    search_fields = ("name", "description")


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ("subtotal",)
    raw_id_fields = ("product",)

    def subtotal(self, obj: OrderItem) -> str:
        return f"${obj.subtotal}"


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "guest", "status", "total_amount", "message", "created_at")
    list_filter = ("status",)
    search_fields = ("guest__phone", "guest__first_name", "message")
    readonly_fields = ("id", "total_amount", "created_at", "updated_at")
    raw_id_fields = ("guest", "booking")
    inlines = [OrderItemInline]

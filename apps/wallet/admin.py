from django.contrib import admin

from .models import PaymentMethod, StripeCustomer, Transaction, WalletBalance


@admin.register(StripeCustomer)
class StripeCustomerAdmin(admin.ModelAdmin):
    list_display = ("guest", "stripe_customer_id", "created_at")
    search_fields = ("guest__phone", "guest__first_name", "stripe_customer_id")
    raw_id_fields = ("guest",)


@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = ("guest", "type", "card_brand", "card_last4", "is_default", "created_at")
    list_filter = ("type", "is_default")
    raw_id_fields = ("guest",)


@admin.register(WalletBalance)
class WalletBalanceAdmin(admin.ModelAdmin):
    list_display = ("guest", "balance", "currency", "updated_at")
    search_fields = ("guest__phone", "guest__first_name")
    raw_id_fields = ("guest",)


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ("guest", "type", "amount", "balance_after", "description", "created_at")
    list_filter = ("type",)
    search_fields = ("guest__phone", "description")
    raw_id_fields = ("guest", "order", "booking")
    readonly_fields = ("created_at",)

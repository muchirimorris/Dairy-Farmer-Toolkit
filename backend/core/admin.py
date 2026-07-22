from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Farmer, Animal, MilkLog, HealthRecord, FeedInventory, FinancialRecord

@admin.register(Farmer)
class FarmerAdmin(UserAdmin):
    pass

@admin.register(Animal)
class AnimalAdmin(admin.ModelAdmin):
    list_display = ('name', 'tag_number', 'breed', 'farmer')
    search_fields = ('name', 'tag_number')

@admin.register(MilkLog)
class MilkLogAdmin(admin.ModelAdmin):
    list_display = ('animal', 'date', 'liters', 'farmer')
    list_filter = ('date', 'farmer')

@admin.register(HealthRecord)
class HealthRecordAdmin(admin.ModelAdmin):
    list_display = ('animal', 'type', 'date', 'farmer')

@admin.register(FeedInventory)
class FeedInventoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'quantity', 'unit', 'farmer')

@admin.register(FinancialRecord)
class FinancialRecordAdmin(admin.ModelAdmin):
    list_display = ('type', 'category', 'amount', 'date', 'farmer')
    list_filter = ('type', 'date')

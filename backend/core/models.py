from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid

class Farmer(AbstractUser):
    # Custom user extending AbstractUser
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # We can add more fields if needed, e.g. farm_name, phone_number, etc.

    def __str__(self):
        return self.username

class Animal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='animals')
    tag_number = models.CharField(max_length=50)
    name = models.CharField(max_length=100)
    breed = models.CharField(max_length=100)
    age = models.IntegerField()
    production_status = models.CharField(max_length=50)
    reproductive_status = models.CharField(max_length=50)
    last_calving_date = models.DateField(null=True, blank=True)
    image_url = models.URLField(max_length=500, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.tag_number} - {self.name}"

class MilkLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='milk_logs')
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='milk_logs')
    date = models.DateTimeField()
    liters = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.animal.name} - {self.liters}L on {self.date}"

class HealthRecord(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='health_records')
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='health_records')
    type = models.CharField(max_length=50) # 'vaccination', 'disease', 'treatment', 'vet_visit'
    date = models.DateTimeField()
    description = models.TextField()
    medicine_used = models.CharField(max_length=200, null=True, blank=True)
    cost = models.FloatField(null=True, blank=True)
    next_follow_up = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.animal.name} - {self.type} on {self.date}"

class FeedInventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='feed_inventory')
    type = models.CharField(max_length=50) # 'Hay', 'Silage', 'Concentrate', 'Minerals'
    name = models.CharField(max_length=100)
    quantity = models.FloatField()
    unit = models.CharField(max_length=20)
    cost = models.FloatField()
    purchase_date = models.DateTimeField()
    threshold = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.quantity} {self.unit}"

class FinancialRecord(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='financial_records')
    type = models.CharField(max_length=20) # 'income' or 'expense'
    amount = models.FloatField()
    category = models.CharField(max_length=50)
    date = models.DateTimeField()
    animal = models.ForeignKey(Animal, on_delete=models.SET_NULL, null=True, blank=True, related_name='financial_records')
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.type.capitalize()} - ${self.amount} on {self.date}"

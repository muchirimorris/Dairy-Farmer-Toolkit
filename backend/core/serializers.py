from rest_framework import serializers
from .models import Farmer, Animal, MilkLog, HealthRecord, FeedInventory, FinancialRecord

class FarmerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Farmer
        fields = ('id', 'username', 'email')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Farmer
        fields = ('id', 'username', 'email', 'password')

    def create(self, validated_data):
        user = Farmer.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )
        return user

class AnimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Animal
        fields = '__all__'
        read_only_fields = ('farmer',)

class MilkLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MilkLog
        fields = '__all__'
        read_only_fields = ('farmer',)

class HealthRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthRecord
        fields = '__all__'
        read_only_fields = ('farmer',)

class FeedInventorySerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedInventory
        fields = '__all__'
        read_only_fields = ('farmer',)

class FinancialRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = FinancialRecord
        fields = '__all__'
        read_only_fields = ('farmer',)

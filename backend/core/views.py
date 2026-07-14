from rest_framework import viewsets, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Animal, MilkLog, HealthRecord, FeedInventory, FinancialRecord, Farmer
from .serializers import (AnimalSerializer, MilkLogSerializer, HealthRecordSerializer, 
                          FeedInventorySerializer, FinancialRecordSerializer, RegisterSerializer, FarmerSerializer)

class RegisterView(generics.CreateAPIView):
    queryset = Farmer.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

class CurrentUserView(generics.RetrieveAPIView):
    serializer_class = FarmerSerializer
    
    def get_object(self):
        return self.request.user

class FarmerOwnedViewSet(viewsets.ModelViewSet):
    """
    A base viewset that automatically filters queries and sets the 'farmer'
    to the currently authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(farmer=self.request.user)

    def perform_create(self, serializer):
        serializer.save(farmer=self.request.user)

class AnimalViewSet(FarmerOwnedViewSet):
    queryset = Animal.objects.all()
    serializer_class = AnimalSerializer

class MilkLogViewSet(FarmerOwnedViewSet):
    queryset = MilkLog.objects.all()
    serializer_class = MilkLogSerializer

class HealthRecordViewSet(FarmerOwnedViewSet):
    queryset = HealthRecord.objects.all()
    serializer_class = HealthRecordSerializer

class FeedInventoryViewSet(FarmerOwnedViewSet):
    queryset = FeedInventory.objects.all()
    serializer_class = FeedInventorySerializer

class FinancialRecordViewSet(FarmerOwnedViewSet):
    queryset = FinancialRecord.objects.all()
    serializer_class = FinancialRecordSerializer

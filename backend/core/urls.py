from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (AnimalViewSet, MilkLogViewSet, HealthRecordViewSet, 
                    FeedInventoryViewSet, FinancialRecordViewSet, RegisterView, CurrentUserView)

router = DefaultRouter()
router.register(r'animals', AnimalViewSet, basename='animal')
router.register(r'milk-logs', MilkLogViewSet, basename='milklog')
router.register(r'health-records', HealthRecordViewSet, basename='healthrecord')
router.register(r'feed-inventory', FeedInventoryViewSet, basename='feedinventory')
router.register(r'financial-records', FinancialRecordViewSet, basename='financialrecord')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', RegisterView.as_view(), name='register'),
    path('me/', CurrentUserView.as_view(), name='current_user'),
]

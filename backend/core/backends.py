from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend
from django.db import models

class EmailOrUsernameModelBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        UserModel = get_user_model()
        if username is None:
            username = kwargs.get(UserModel.USERNAME_FIELD)
            
        try:
            # Try to fetch the user by searching the username or email field
            user = UserModel.objects.get(
                models.Q(username__iexact=username) | models.Q(email__iexact=username)
            )
        except UserModel.DoesNotExist:
            # Run the default password hasher once to reduce the timing
            # difference between an existing and a non-existing user.
            UserModel().set_password(password)
            return None
            
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
            
        return None

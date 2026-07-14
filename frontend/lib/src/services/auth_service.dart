import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class User {
  final String id;
  final String username;
  final String email;

  User({required this.id, required this.username, required this.email});
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('user_id');
    final username = prefs.getString('username');
    final email = prefs.getString('email');
    
    if (token != null && userId != null) {
      _currentUser = User(id: userId, username: username ?? '', email: email ?? '');
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.post('/token/', {
        'username': username,
        'password': password,
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access']);
      await prefs.setString('refresh_token', response['refresh']);
      
      // Fetch user profile
      final userResponse = await _apiService.get('/me/');
      
      final userId = userResponse['id'] ?? username;
      final userEmail = userResponse['email'] ?? '';
      
      _currentUser = User(id: userId, username: username, email: userEmail);
      await prefs.setString('user_id', userId);
      await prefs.setString('username', username);
      await prefs.setString('email', userEmail);
      
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.post('/register/', {
        'username': username,
        'email': email,
        'password': password,
      });

      // Automatically login after successful registration
      await login(username, password);
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    
    _currentUser = null;
    notifyListeners();
  }
}

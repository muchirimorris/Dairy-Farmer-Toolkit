import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static void Function()? onLogout;

  // Use local network IP for physical device testing
  static String get baseUrl {
    return 'http://10.4.137.234:8000/api';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) {
      onLogout?.call();
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/token/refresh/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access']);
        return true;
      } else {
        onLogout?.call();
        return false;
      }
    } catch (e) {
      onLogout?.call();
      return false;
    }
  }

  Future<dynamic> _request(
    String method, 
    String endpoint, 
    {Map<String, dynamic>? data}
  ) async {
    Uri url = Uri.parse('$baseUrl$endpoint');
    Map<String, String> headers = await _getHeaders();
    http.Response response;

    Future<http.Response> makeCall() async {
      switch (method) {
        case 'GET': return await http.get(url, headers: headers);
        case 'POST': return await http.post(url, headers: headers, body: jsonEncode(data));
        case 'PUT': return await http.put(url, headers: headers, body: jsonEncode(data));
        case 'DELETE': return await http.delete(url, headers: headers);
        default: throw Exception('Unsupported method: $method');
      }
    }

    try {
      response = await makeCall();

      if (response.statusCode == 401 && endpoint != '/token/' && endpoint != '/token/refresh/') {
        // Try refreshing token
        final success = await _refreshToken();
        if (success) {
          headers = await _getHeaders(); // Get new token
          response = await makeCall(); // Retry original request
        }
      }
      
      return _processResponse(response);
    } catch (e) {
      debugPrint('$method Error: $e');
      rethrow;
    }
  }

  Future<dynamic> get(String endpoint) => _request('GET', endpoint);
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) => _request('POST', endpoint, data: data);
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) => _request('PUT', endpoint, data: data);
  Future<dynamic> delete(String endpoint) => _request('DELETE', endpoint);

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'API Error: ${response.statusCode}';
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData.isNotEmpty) {
          // Typically Django returns {"field": ["Error msg"]} or {"detail": "Error msg"}
          final firstError = errorData.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else if (firstError is String) {
            errorMessage = firstError;
          } else {
            errorMessage = errorData.toString();
          }
        }
      } catch (_) {
        // Fallback for non-JSON or weird responses
        if (response.body.isNotEmpty && response.body.length < 150) {
          errorMessage = response.body;
        }
      }
      debugPrint('API Error details: ${response.statusCode} - ${response.body}');
      throw Exception(errorMessage);
    }
  }
}

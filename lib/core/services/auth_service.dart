import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://192.168.0.105:3000';

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _cachedProfileKey = 'cached_profile';
  static const String _cachedNameKey = 'cached_name';
  static const String _cachedPhoneKey = 'cached_phone';

  Future<bool> requestOtp(String phoneNumber) async {
    try {
      var cleanPhone = phoneNumber.replaceAll(' ', '');
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('8')) {
          cleanPhone = '+7${cleanPhone.substring(1)}';
        } else if (cleanPhone.startsWith('7')) {
          cleanPhone = '+$cleanPhone';
        } else {
          // Fallback, but practically should be user error if here
          // Assume needs +7 if length is 10
          if (cleanPhone.length == 10) cleanPhone = '+7$cleanPhone';
        }
      }
      print('Requesting OTP for: $cleanPhone');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': cleanPhone}),
      );

      print('Request OTP Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Request OTP error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(
    String phoneNumber,
    String code,
  ) async {
    try {
      var cleanPhone = phoneNumber.replaceAll(' ', '');
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('8')) {
          cleanPhone = '+7${cleanPhone.substring(1)}';
        } else if (cleanPhone.startsWith('7')) {
          cleanPhone = '+$cleanPhone';
        } else {
          if (cleanPhone.length == 10) cleanPhone = '+7$cleanPhone';
        }
      }
      print('Verifying OTP: $cleanPhone with code: $code');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': cleanPhone, 'code': code}),
      );

      print('Verify OTP Status: ${response.statusCode}');
      print('Verify OTP Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          await _saveTokens(accessToken, refreshToken);
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Verify OTP error: $e');
      return null;
    }
  }

  // Helper method for authenticated requests with auto-refresh
  Future<http.Response?> _authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
      } else if (method == 'PATCH') {
        response = await http.patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        response = await http.get(url, headers: headers);
      }

      // If token expired, try to refresh
      if (response.statusCode == 401) {
        print('Token expired, attempting refresh...');
        final refreshSuccess = await refreshTokens();
        if (refreshSuccess) {
          token = await getAccessToken();
          headers['Authorization'] = 'Bearer $token';
          print('Token refreshed, retrying request...');

          // Retry request with new token
          if (method == 'POST') {
            response = await http.post(
              url,
              headers: headers,
              body: jsonEncode(body),
            );
          } else if (method == 'PATCH') {
            response = await http.patch(
              url,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
          } else {
            response = await http.get(url, headers: headers);
          }
        } else {
          print('Token refresh failed.');
          // Optional: Logout user if refresh fails
          // await logout();
        }
      }
      return response;
    } catch (e) {
      print('Authenticated request error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final response = await _authenticatedRequest(
      method: 'GET',
      endpoint: '/user/me',
    );

    if (response != null) {
      print('Get Profile Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cacheProfile(data);
        return data;
      }
    }
    return null;
  }

  Future<bool> updateProfile(String firstName, String? lastName) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: '/auth/edit/profile',
      body: {'firstName': firstName, 'lastName': lastName},
    );
    return response != null &&
        (response.statusCode == 200 || response.statusCode == 201);
  }

  // Update driver profile (car details)
  Future<bool> updateDriverProfile({
    required String carModel,
    required String carNumber,
    required String carColor,
  }) async {
    final response = await _authenticatedRequest(
      method: 'POST',
      endpoint: '/driver/profile',
      body: {
        'carModel': carModel,
        'carNumber': carNumber,
        'carColor': carColor,
      },
    );
    return response != null &&
        (response.statusCode == 200 || response.statusCode == 201);
  }

  // Switch role to driver
  Future<bool> switchToDriver() async {
    final response = await _authenticatedRequest(
      method: 'PATCH',
      endpoint: '/user/switch-role',
    );
    return response != null &&
        (response.statusCode == 200 || response.statusCode == 201);
  }

  Future<bool> refreshTokens() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await _saveTokens(newAccessToken, newRefreshToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_cachedNameKey);
    await prefs.remove(_cachedPhoneKey);
  }

  // Cache profile data
  Future<void> _cacheProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = profile['firstName'] ?? '';
    final lastName = profile['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    await prefs.setString(
      _cachedNameKey,
      fullName.isEmpty ? 'Пользователь' : fullName,
    );
    await prefs.setString(_cachedPhoneKey, profile['phoneNumber'] ?? '');
  }

  // Get cached profile name
  Future<String> getCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedNameKey) ?? 'Пользователь';
  }

  // Get cached phone number
  Future<String> getCachedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedPhoneKey) ?? '';
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}

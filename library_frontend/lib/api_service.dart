// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
static const String _baseUrl = 'https://localhost:7270/api/';
  
  static Future<String?> login(String password, String email) async {
    final url = Uri.parse("${_baseUrl}auth/login");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

  print(response.statusCode);
  if (response.statusCode == 200 || response.statusCode == 204) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['accessToken'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        return token;
      } else {
        print("login failed");
      }
    }
    return null;
  }

  static Future<int> addUser(String name, String email, String pass) async {
    final url = Uri.parse("${_baseUrl}auth/register");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': name,
        'email': email,
        "password": pass,
      }),
    );

    return response.statusCode;
  }
}

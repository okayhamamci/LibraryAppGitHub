// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_frontend/Models-Providers/book.dart';
import 'package:library_frontend/Models-Providers/borrowrecord.dart';
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

    static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<List<Book>> fetchAvailableBooks() async {
    final res = await http.get(
      Uri.parse('${_baseUrl}book/GetAvailableBooks'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Available books failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

    static Future<List<Book>> fetchArchivedBooks() async {
    final res = await http.get(
      Uri.parse('${_baseUrl}book/GetArchivedBooks'),
      headers: {'Accept': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Available books failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<BorrowRecord>> fetchMyBorrowings({required bool ongoingOnly}) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');

    final path = ongoingOnly ? 'borrow/my/ongoing' : 'borrow/my/all';
    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Unauthorized – please log in again.');
    if (res.statusCode != 200) {
      throw Exception('Borrowings failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BorrowRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

    static Future<List<BorrowRecord>> fetchMyBorrowingsAdmin({required bool ongoingOnly}) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');

    final path = ongoingOnly ? 'borrow/GetAllOngoingRecords' : 'borrow/GetAllTimeRecords';
    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 401) throw Exception('Unauthorized – please log in again.');
    if (res.statusCode != 200) {
      throw Exception('Borrowings failed: ${res.statusCode} ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BorrowRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> borrowBook(int bookId) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.post(
      Uri.parse('${_baseUrl}borrow/BorrowBook/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Borrow failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> returnBook(int bookId) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.post(
      Uri.parse('${_baseUrl}borrow/ReturnBook/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Return failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> deleteBook(int bookId) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.patch(
      Uri.parse('${_baseUrl}book/ArchiveBook/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 204) {
      throw Exception('Return failed: ${res.statusCode} ${res.body}');
    }
  }

    static Future<void> unArchiveBook(int bookId) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.patch(
      Uri.parse('${_baseUrl}book/UnarchiveBook/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 204) {
      throw Exception('Return failed: ${res.statusCode} ${res.body}');
    }
  }

    static Future<void> addBook(String title, String author) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');
    Uri url = Uri.parse("${_baseUrl}book/addBook");
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'Title': title,
        'Author': author,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Return failed: ${res.statusCode} ${res.body}');
    }
  }
}

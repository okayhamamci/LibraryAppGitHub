// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:library_frontend/Models-Providers/book.dart';
import 'package:library_frontend/Models-Providers/borrowrecord.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
static const String _baseUrl = 'https://localhost:7270/api/';
static const String _aiBase  = 'http://localhost:8000';
  
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

    static Future<void> addBook(String title, String author, String genre, String descr, double rating, int page) async {
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
        "Genre" : genre,
        "Page": page,
        "Description" : descr, 
        "Rating" : rating,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Return failed: ${res.statusCode} ${res.body}');
    }
  }
  
    static Future<int?> getUserIdFromToken() async {
    final token = await _token();
    if (token == null) return null;

    final decoded = JwtDecoder.decode(token);
    // Try common keys in order:
    final keys = <String>[
      'nameid', // some backends
      'sub', // sometimes used
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier', // YOURS
    ];

    for (final k in keys) {
      final v = decoded[k];
      if (v != null) {
        final id = int.tryParse(v.toString());
        if (id != null) return id;
      }
    }
    return null;
  }

  static Future<List<int>> fetchAiSimilarIds(int userId, {int topK = 3}) async {
    final uri = Uri.parse('$_aiBase/recommend_similar?user_id=$userId&top_k=$topK');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('AI similar IDs failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => e as int).toList();
  }

  static Future<List<Book>> fetchAiSimilarBooks(int userId, {int topK = 3}) async {
    final ids = await fetchAiSimilarIds(userId, topK: topK);
    //print(ids);
    if (ids.isEmpty) return [];
    final all = await fetchAvailableBooks();
    final mapById = { for (final b in all) b.id : b };
    final result = <Book>[];
    for (final id in ids) {
      final b = mapById[id];
      if (b != null) result.add(b);
    }
    return result;
  }
}

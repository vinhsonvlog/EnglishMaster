import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:englishmaster/models/flashcard.dart';
class ApiService {
  // LƯU Ý QUAN TRỌNG:
  // - Máy ảo Android (Emulator): dùng 'http://10.0.2.2:1124/api'
  // - Máy ảo iOS (Simulator): dùng 'http://localhost:1124/api'
  // - Điện thoại thật: dùng IP máy tính của bạn, ví dụ 'http://192.168.1.x:1124/api'
  // - Máy thật: dùng IP máy tính của bạn, ví dụ 'http://192.168.2.99:1124/api:

  //static const String baseUrl = 'http://localhost:1124/api';
  static const String baseUrl = 'http://10.0.2.2:1124/api';
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  // --- AUTHENTICATION ---

  // Đăng ký
  Future<dynamic> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Đăng ký thất bại');
    }
  }

  // Đăng nhập
  Future<dynamic> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // Lưu token và thông tin user cơ bản
      final token = data['token'];
      if (token == null || token is! String) {
        throw Exception('Đăng nhập thành công nhưng không nhận được token.');
      }
      await prefs.setString('token', token);
      if (data['user'] != null && data['user'] is Map) {
        await prefs.setString('userId', data['user']['_id'] ?? '');
        await prefs.setString('username', data['user']['username'] ?? '');
      }
      return data;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Đăng nhập thất bại');
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa hết token
  }

  // --- LESSONS ---

  Future<List<dynamic>> getLessons() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lessons'), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<dynamic>.from(json['data']);
    } else {
      throw Exception('Không thể tải bài học: ${response.body}');
    }
  }

  static String getValidImageUrl(String url) {
    if (url == null || url.isEmpty) return "";

    // Nếu ảnh là đường dẫn tương đối (/uploads/...) -> Nối thêm domain
    if (!url.startsWith('http')) {
      String host = baseUrl.replaceAll('/api', ''); // Lấy root domain
      // Xử lý trường hợp url bắt đầu bằng / hoặc không
      return url.startsWith('/') ? '$host$url' : '$host/$url';
    }
    return url;
  }
  // --- FLASHCARDS (DECKS) ---

  // 1. Lấy danh sách bộ thẻ (Decks)
  Future<List<dynamic>> getDecks() async {
    final headers = await _getHeaders();

    // SỬA LỖI: Dùng endpoint /browse cho user thường
    final response = await http.get(Uri.parse('$baseUrl/decks/browse'), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Backend trả về { data: { decks: [] } }
      if (json['data'] != null && json['data']['decks'] != null) {
        return List<dynamic>.from(json['data']['decks']);
      }
      return [];
    } else {
      print('Lỗi tải decks: ${response.body}');
      return [];
    }
  }

  // --- FLASHCARD DETAIL ---

  // 2. Lấy chi tiết thẻ trong một bộ (Flashcards)
  Future<List<Flashcard>> getFlashcardsByDeck(String deckId) async {
    final headers = await _getHeaders();

    // SỬA LỖI: Gọi đúng route backend
    final response = await http.get(
        Uri.parse('$baseUrl/decks/$deckId/flashcards'),
        headers: headers
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['data'] != null && json['data']['flashcards'] != null) {
        final List<dynamic> list = json['data']['flashcards'];
        return list.map((item) => Flashcard.fromJson(item)).toList();
      }
      return [];
    } else {
      throw Exception('Không thể tải thẻ: ${response.statusCode}');
    }
  }
  // --- USER PROFILE ---

  // Lấy thông tin chi tiết người dùng (để hiển thị Avatar, XP, Streak)
  Future<dynamic> getUserProfile() async {
    final headers = await _getHeaders();
    // Endpoint thường gặp: /auth/me hoặc /users/profile
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tải thông tin người dùng');
    }
  }

  // --- LESSON DETAILS ---

  // Lấy chi tiết 1 bài học
  Future<dynamic> getLessonById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lessons/$id'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception('Không tải được bài học');
  }

  // Lấy từ vựng của bài học
  Future<List<dynamic>> getVocabulariesByLesson(String lessonId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/vocabularies'), headers: headers);
    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body)['data']);
    }
    return [];
  }

  // Lấy bài tập của bài học
  Future<List<dynamic>> getExercisesByLesson(String lessonId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/exercises'), headers: headers);
    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body)['data']);
    }
    return [];
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:englishmaster/models/flashcard.dart';
import '../models/api_response.dart';
import 'api_handler.dart';

class ApiService {
  // Chọn IP phù hợp:
  // static const String baseUrl = 'http://localhost:1124/api'; // iOS Simulator
  static const String baseUrl = 'http://10.0.2.2:1124/api'; // Android Emulator
  // static const String baseUrl = 'http://192.168.1.x:1124/api'; // Máy thật

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- AUTHENTICATION ---
  Future<ApiResponse<dynamic>> register(String name, String email, String password, String age) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'age': age.isNotEmpty ? int.tryParse(age) : null,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.success(jsonDecode(response.body));
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  Future<ApiResponse<dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      if (response.statusCode == 200) return ApiResponse.success(jsonDecode(response.body));
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  Future<dynamic> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        return {'error': body['message'] ?? 'Không thể gửi lại mã'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<ApiResponse<dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requires2FA'] != true) {
          final prefs = await SharedPreferences.getInstance();
          final token = data['token'];
          if (token != null) {
            await prefs.setString('token', token);
            if (data['user'] != null) {
              await prefs.setString('userId', data['user']['_id'] ?? data['user']['id'] ?? '');
              await prefs.setString('username', data['user']['name'] ?? '');
            }
          }
        }
        return ApiResponse.success(data);
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- QUÊN MẬT KHẨU ---

  Future<dynamic> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      }
      return {'error': body['message'] ?? 'Không thể gửi mã xác nhận'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<dynamic> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body;
      }
      return {'error': body['message'] ?? 'Đặt lại mật khẩu thất bại'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- PROGRESS ---
  Future<ApiResponse<Map<String, dynamic>>> getUserProgress() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/progress'), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(Map<String, dynamic>.from(json['data'] ?? {}));
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  // --- LUYỆN TẬP & KIỂM TRA ---

  Future<List<dynamic>> getPracticeExercises() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/practice/exercises'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<dynamic>.from(json['data'] ?? []);
      } else {
        print('Lỗi tải bài tập: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  // Lấy danh sách bài kiểm tra
  Future<List<dynamic>> getTests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tests'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null && json['data'] is Map && json['data']['tests'] != null) {
          return List<dynamic>.from(json['data']['tests']);
        }
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<dynamic> getPracticeExerciseById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/practice/exercises/$id'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<dynamic> getTestById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tests/$id'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  // --- THÀNH TÍCH (ACHIEVEMENTS) ---
  Future<List<dynamic>> getAchievements() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/achievements'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<dynamic>.from(json['data'] ?? []);
      }
    } catch (e) {
      print("Lỗi getAchievements: $e");
    }
    return [];
  }

  // --- XỬ LÝ DỮ LIỆU AN TOÀN (Helper) ---
  List<dynamic> _parseListResponse(dynamic responseBody) {
    if (responseBody is List) return responseBody;
    if (responseBody is Map) {
      if (responseBody['data'] is List) return List<dynamic>.from(responseBody['data']);
      if (responseBody['users'] is List) return List<dynamic>.from(responseBody['users']);
      if (responseBody['items'] is List) return List<dynamic>.from(responseBody['items']);
    }
    return [];
  }

  // --- XẾP HẠNG (LEADERBOARD) ---
  Future<ApiResponse<List<dynamic>>> getLeaderboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/leaderboard/overall'), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['data'] as List).map((item) {
          final userInfo = item['user'] ?? {};
          return {
            'name': userInfo['name'] ?? userInfo['username'] ?? 'Người dùng',
            'avatar': ApiService.getValidImageUrl(userInfo['avatar']),
            'xp': item['xpTotal'] ?? 0,
          };
        }).toList();
        return ApiResponse.success(list);
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  // --- CỬA HÀNG (SHOP) ---
  Future<List<dynamic>> getShopItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/shop/items'), headers: headers);
      if (response.statusCode == 200) {
        return _parseListResponse(jsonDecode(response.body));
      }
    } catch (e) {
      print("Lỗi getShopItems: $e");
    }
    return [];
  }

  Future<ApiResponse<bool>> buyItem(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
          Uri.parse('$baseUrl/shop/buy'),
          headers: headers,
          body: jsonEncode({'itemId': itemId})
      );
      if (response.statusCode == 200) return ApiResponse.success(true);
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }


  // --- LESSONS ---
  Future<ApiResponse<List<dynamic>>> getLessons() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons'), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(List<dynamic>.from(json['data'] ?? []));
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  // --- FLASHCARDS & PROFILE ---
  static String getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (!url.startsWith('http')) {
      String host = baseUrl.replaceAll('/api', '');
      return url.startsWith('/') ? '$host$url' : '$host/$url';
    }
    return url;
  }

  Future<List<dynamic>> getDecks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/decks/browse'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['decks'] != null) {
          return List<dynamic>.from(json['data']['decks']);
        }
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<ApiResponse<List<Flashcard>>> getFlashcardsByDeck(String deckId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/decks/$deckId/flashcards'), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['data']['flashcards'] ?? [];
        return ApiResponse.success(list.map((item) => Flashcard.fromJson(item)).toList());
      }
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  Future<ApiResponse<dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/profile'), headers: headers);
      if (response.statusCode == 200) return ApiResponse.success(jsonDecode(response.body));
      return ApiResponse.error(ApiHandler.getErrorMessage(response));
    } catch (e) {
      return ApiResponse.error(ApiHandler.handleException(e));
    }
  }

  // --- LESSON DETAILS ---
  Future<dynamic> getLessonById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons/$id'), headers: headers);
      if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<List<dynamic>> getVocabulariesByLesson(String lessonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/vocabularies'), headers: headers);
      if (response.statusCode == 200) return List<dynamic>.from(jsonDecode(response.body)['data']);
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<List<dynamic>> getExercisesByLesson(String lessonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/exercises'), headers: headers);
      if (response.statusCode == 200) return List<dynamic>.from(jsonDecode(response.body)['data']);
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<dynamic>.from(json['data'] ?? []);
      }
    } catch (e) {
      print("Lỗi tải thông báo: $e");
    }
    return [];
  }
}
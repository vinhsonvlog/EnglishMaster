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

  Future<ApiResponse<Map<String, dynamic>>> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Đã gửi lại mã OTP',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể gửi lại mã';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseBody = jsonDecode(response.body);

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

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Đã gửi mã xác nhận',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể gửi mã xác nhận';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> resetPassword(String email, String otp, String newPassword) async {
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

      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Đặt lại mật khẩu thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Đặt lại mật khẩu thất bại';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // --- PROGRESS ---
  Future<ApiResponse<Map<String, dynamic>>> getUserProgress() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/progress'), headers: headers);

      final responseBody = jsonDecode(response.body);

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

  Future<ApiResponse<List<dynamic>>> getPracticeExercises() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/practice/exercises'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách bài tập thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải bài tập';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Lấy danh sách bài kiểm tra
  Future<ApiResponse<List<dynamic>>> getTests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tests'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        List<dynamic> tests = [];
        if (responseBody['data'] != null && responseBody['data'] is Map && responseBody['data']['tests'] != null) {
          tests = List<dynamic>.from(responseBody['data']['tests']);
        }
        return ApiResponse.success(
          tests,
          message: 'Lấy danh sách bài kiểm tra thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải bài kiểm tra';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPracticeExerciseById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/practice/exercises/$id'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody['data'] ?? {},
          message: 'Lấy bài tập thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không tìm thấy bài tập';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getTestById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tests/$id'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody['data'] ?? {},
          message: 'Lấy bài kiểm tra thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không tìm thấy bài kiểm tra';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // --- THÀNH TÍCH (ACHIEVEMENTS) ---
  Future<ApiResponse<List<dynamic>>> getAchievements() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/achievements'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách thành tích thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải thành tích';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
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

      final responseBody = jsonDecode(response.body);

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
  Future<ApiResponse<List<dynamic>>> getShopItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/shop/items'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          _parseListResponse(responseBody),
          message: 'Lấy danh sách vật phẩm thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải danh sách vật phẩm';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
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

      final responseBody = jsonDecode(response.body);

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

  Future<ApiResponse<List<dynamic>>> getDecks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/decks/browse'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        List<dynamic> decks = [];
        if (responseBody['data'] != null && responseBody['data']['decks'] != null) {
          decks = List<dynamic>.from(responseBody['data']['decks']);
        }
        return ApiResponse.success(
          decks,
          message: 'Lấy danh sách bộ thẻ thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải danh sách bộ thẻ';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<List<Flashcard>>> getFlashcardsByDeck(String deckId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/decks/$deckId/flashcards'), headers: headers);

      final responseBody = jsonDecode(response.body);

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
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody['data'] ?? {},
          message: 'Lấy chi tiết bài học thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không tìm thấy bài học';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getVocabulariesByLesson(String lessonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/vocabularies'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách từ vựng thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải từ vựng';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getExercisesByLesson(String lessonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/exercises'), headers: headers);
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách bài tập thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải bài tập';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: headers);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách thông báo thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải thông báo';
      return ApiResponse.failure(
        errorMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        'Lỗi kết nối: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
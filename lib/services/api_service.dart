import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:englishmaster/models/flashcard.dart';

// Model cho API Response
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.failure(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: ApiError(message: message, statusCode: statusCode),
    );
  }
}

// Model cho API Error
class ApiError {
  final String message;
  final int? statusCode;
  final String? field;

  ApiError({
    required this.message,
    this.statusCode,
    this.field,
  });

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiError(
      message: json['message'] ?? 'Đã xảy ra lỗi',
      statusCode: statusCode,
      field: json['field'],
    );
  }
}

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

  Future<ApiResponse<Map<String, dynamic>>> register(String name, String email, String password, String age) async {
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

      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Đăng ký thành công',
        );
      }
      
      // Xử lý lỗi cụ thể từ backend
      final errorMessage = responseBody['message'] ?? 'Đăng ký thất bại';
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

  Future<ApiResponse<Map<String, dynamic>>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Xác thực OTP thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Mã OTP không đúng';
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

  Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Nếu yêu cầu 2FA, trả về ngay
        if (responseBody['requires2FA'] == true) {
          return ApiResponse.success(
            responseBody,
            message: 'Yêu cầu xác thực 2FA',
          );
        }

        // Lưu token và thông tin user
        final prefs = await SharedPreferences.getInstance();
        final token = responseBody['token'];
        if (token != null) {
          await prefs.setString('token', token);
          if (responseBody['user'] != null && responseBody['user'] is Map) {
            await prefs.setString('userId', responseBody['user']['_id'] ?? responseBody['user']['id'] ?? '');
            await prefs.setString('username', responseBody['user']['name'] ?? '');
          }
        }
        
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Đăng nhập thành công',
        );
      }
      
      // Xử lý lỗi cụ thể từ backend
      final errorMessage = responseBody['message'] ?? 'Đăng nhập thất bại';
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

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print(e);
    }
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
        return ApiResponse.success(
          responseBody['data'] ?? {'completedLessons': [], 'currentLesson': null},
          message: 'Lấy tiến độ thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể lấy tiến độ';
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

  Future<ApiResponse<Map<String, dynamic>>> updateProgress(String lessonId, int score) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/progress/update'),
        headers: headers,
        body: jsonEncode({
          'lessonId': lessonId,
          'score': score,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Cập nhật tiến độ thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Cập nhật thất bại';
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
        final list = responseBody['data'] as List;

        final leaderboard = list.map((item) {
          final userInfo = item['user'] ?? {};
          return {
            'name': userInfo['name'] ?? userInfo['username'] ?? 'Người dùng',
            'avatar': ApiService.getValidImageUrl(userInfo['avatar']),
            'xp': item['xpTotal'] ?? 0,
          };
        }).toList();
        
        return ApiResponse.success(
          leaderboard,
          message: 'Lấy bảng xếp hạng thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải bảng xếp hạng';
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

  Future<ApiResponse<Map<String, dynamic>>> buyItem(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
          Uri.parse('$baseUrl/shop/buy'),
          headers: headers,
          body: jsonEncode({'itemId': itemId})
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: responseBody['message'] ?? 'Mua vật phẩm thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể mua vật phẩm';
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


  // --- LESSONS ---

  Future<ApiResponse<List<dynamic>>> getLessons() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/lessons'), headers: headers);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          List<dynamic>.from(responseBody['data'] ?? []),
          message: 'Lấy danh sách bài học thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải danh sách bài học';
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
        List<Flashcard> flashcards = [];
        if (responseBody['data'] != null && responseBody['data']['flashcards'] != null) {
          final List<dynamic> list = responseBody['data']['flashcards'];
          flashcards = list.map((item) => Flashcard.fromJson(item)).toList();
        }
        return ApiResponse.success(
          flashcards,
          message: 'Lấy danh sách flashcard thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể tải danh sách flashcard';
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

  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/profile'), headers: headers);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          responseBody,
          message: 'Lấy thông tin người dùng thành công',
        );
      }
      
      final errorMessage = responseBody['message'] ?? 'Không thể lấy thông tin người dùng';
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

  // --- LESSON DETAILS ---

  Future<ApiResponse<Map<String, dynamic>>> getLessonById(String id) async {
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
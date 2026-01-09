import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHandler {
  /// Hàm tĩnh để xử lý lỗi từ Server trả về
  static String getErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      // Ưu tiên lấy message từ server, nếu không có mới dùng mã code
      return body['message'] ?? body['error'] ?? 'Lỗi hệ thống (${response.statusCode})';
    } catch (e) {
      return 'Lỗi không xác định: ${response.statusCode}';
    }
  }

  /// Hàm xử lý các lỗi ngoại lệ (Mất mạng, Timeout, ...)
  static String handleException(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    }
    return 'Đã xảy ra lỗi: $e';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHandler {
  static String getErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? body['error'] ?? 'Lỗi hệ thống (${response.statusCode})';
    } catch (e) {
      return 'Lỗi không xác định: ${response.statusCode}';
    }
  }

  static String handleException(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    }
    return 'Đã xảy ra lỗi: $e';
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  // Factory để tạo object khi thành công
  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  // Factory để tạo object khi thất bại
  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      data: null,
      message: message,
    );
  }
}

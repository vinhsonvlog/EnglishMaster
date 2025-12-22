import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart'; // Đảm bảo file này tồn tại
import 'package:englishmaster/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers cho form đăng ký
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  // Controller cho OTP
  final _otpController = TextEditingController();

  final _apiService = ApiService();

  bool _isLoading = false;
  bool _showOtpForm = false; // State để chuyển đổi giữa form đăng ký và form OTP

  // Xử lý Đăng ký (Bước 1)
  void _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Vui lòng điền đầy đủ thông tin bắt buộc', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _ageController.text,
      );

      if (!mounted) return;

      // Thành công bước 1, chuyển sang form OTP
      setState(() {
        _showOtpForm = true;
        _isLoading = false;
      });

      _showSnack('Đăng ký thành công! Vui lòng kiểm tra email để lấy mã OTP.', Colors.green);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Lỗi: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
  }

  // Xử lý Xác thực OTP (Bước 2)
  void _handleVerifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showSnack('Vui lòng nhập mã OTP', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.verifyOtp(
        _emailController.text,
        _otpController.text,
      );

      if (!mounted) return;

      _showSnack('Xác thực thành công! Tài khoản đã được kích hoạt.', Colors.green);

      // Đợi 1 chút rồi quay về màn hình login
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context); // Quay về Login

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Lỗi: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
  }

  // Xử lý gửi lại mã OTP
  void _handleResendOtp() async {
    try {
      await _apiService.resendOtp(_emailController.text);
      _showSnack('Đã gửi lại mã OTP vào email của bạn.', Colors.blue);
    } catch (e) {
      _showSnack('Lỗi gửi lại mã: ${e.toString()}', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Nếu đang ở màn hình OTP thì quay lại form đăng ký
            if (_showOtpForm) {
              setState(() => _showOtpForm = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: _showOtpForm
                  ? _buildOtpForm()     // Hiển thị form OTP nếu _showOtpForm = true
                  : _buildRegisterForm(), // Hiển thị form Đăng ký nếu _showOtpForm = false
            ),
          ),
        ),
      ),
    );
  }

  // UI Form Đăng ký
  Widget _buildRegisterForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Tạo hồ sơ",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 40),

        // Input Name (Trước đây là Username)
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Tên (Tùy chọn)",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Input Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Input Password
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Mật khẩu",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Input Age (Mới thêm)
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Tuổi (Tùy chọn)",
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Nút Tạo tài khoản
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("TẠO TÀI KHOẢN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // UI Form Nhập OTP
  Widget _buildOtpForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Nhập mã xác minh",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          "Mã OTP đã được gửi đến ${_emailController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),

        // Input OTP
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: "######",
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        // Nút Xác minh
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("XÁC MINH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 16),

        // Nút Gửi lại mã
        TextButton(
          onPressed: _isLoading ? null : _handleResendOtp,
          child: const Text("Gửi lại mã", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
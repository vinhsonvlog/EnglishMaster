import 'dart:async';
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiService _apiService = ApiService();

  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State quản lý UI
  int _currentStep = 1; // 1: Nhập Email, 2: Nhập OTP & Đổi Pass
  bool _isLoading = false;

  // Timer cho nút gửi lại mã
  Timer? _timer;
  int _start = 600; // 10 phút
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 600;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // --- BƯỚC 1: GỬI EMAIL ---
  Future<void> _handleSendEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập email', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📧 Gửi yêu cầu forgot password cho: ${_emailController.text.trim()}');
      final result = await _apiService.forgotPassword(_emailController.text.trim());
      print('✅ Kết quả: $result');

      if (!mounted) return;
      _showSnackBar('Mã xác nhận đã được gửi đến email!', Colors.green);

      // Chuyển sang bước 2
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
      _startTimer();

    } catch (e) {
      print('❌ Lỗi: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
  }

  // Gửi lại mã OTP
  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      _showSnackBar('Mã xác nhận mới đã được gửi!', Colors.green);
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi gửi lại mã: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- BƯỚC 2: ĐẶT LẠI MẬT KHẨU ---
  Future<void> _handleResetPassword() async {
    if (_otpController.text.trim().length != 6) {
      _showSnackBar('Mã OTP phải có 6 số', Colors.orange);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu mới', Colors.orange);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự', Colors.orange);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.resetPassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      _showSnackBar('Đổi mật khẩu thành công! Vui lòng đăng nhập.', Colors.green);

      // Delay xíu rồi về màn hình login
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context); // Về Login

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1); // Quay lại bước nhập email
            } else {
              Navigator.pop(context); // Thoát về login
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: AppColors.primary),
              const SizedBox(height: 20),

              Text(
                _currentStep == 1 ? "Quên Mật Khẩu?" : "Đặt Lại Mật Khẩu",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              Text(
                _currentStep == 1
                    ? "Nhập email của bạn để nhận mã xác nhận."
                    : "Nhập mã OTP đã gửi đến ${_emailController.text}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- FORM BƯỚC 1 (EMAIL) ---
              if (_currentStep == 1) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("GỬI MÃ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],

              // --- FORM BƯỚC 2 (OTP + NEW PASS) ---
              if (_currentStep == 2) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Mã OTP (6 số)",
                    counterText: "",
                    prefixIcon: const Icon(Icons.security),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu mới",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Xác nhận mật khẩu",
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("ĐỔI MẬT KHẨU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 16),
                Center(
                  child: _canResend
                      ? TextButton(
                    onPressed: _isLoading ? null : _handleResendOtp,
                    child: const Text("Gửi lại mã", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  )
                      : Text("Gửi lại mã sau $_start s", style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
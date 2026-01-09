import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/screens/auth/login_screen.dart'; // Bạn cần tạo file này
import 'package:englishmaster/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:englishmaster/services/notification_service.dart'; // Import service vừa tạo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => NotificationService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'App Học Tiếng Anh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Nunito',
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

// Kiểm tra xem user đã đăng nhập chưa để điều hướng
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
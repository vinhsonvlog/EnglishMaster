import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  dynamic _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final profile = await _apiService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      // Xử lý lỗi nếu không tải được
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    await _apiService.logout();
    if (!mounted) return;
    // Quay về màn hình đăng nhập và xóa hết các màn hình trước đó
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Dữ liệu user (nếu lỗi thì hiện mặc định)
    final user = _userProfile ?? {'username': 'Người dùng', 'email': 'user@example.com', 'streak': 0, 'xp': 0};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Màu nền xám nhạt
      appBar: AppBar(
        title: const Text('Hồ sơ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.grey), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phần Header Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                    child: user['avatarUrl'] == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['username'] ?? 'Tên người dùng',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phần Thống kê (Stats)
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.local_fire_department, "${user['streak'] ?? 0}", "Streak", Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(Icons.flash_on, "${user['xp'] ?? 0}", "XP", Colors.yellow[700]!)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(Icons.diamond, "${user['gems'] ?? 0}", "Gems", Colors.blue)),
              ],
            ),
            const SizedBox(height: 20),

            // Menu Options
            _buildMenuOption(Icons.edit, "Chỉnh sửa hồ sơ", () {}),
            _buildMenuOption(Icons.bar_chart, "Thống kê chi tiết", () {}),
            _buildMenuOption(Icons.share, "Chia sẻ bạn bè", () {}),
            const SizedBox(height: 20),

            // Nút Đăng xuất
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("ĐĂNG XUẤT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
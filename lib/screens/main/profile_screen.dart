import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:englishmaster/services/notification_service.dart';

class _ProfileColors {
  static const Color background = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color streakBg = Color(0xFFFEF3C7);
  static const Color streakIcon = Color(0xFFFBBF24);

  static const Color xpBg = Color(0xFFDBEAFE);
  static const Color xpIcon = Color(0xFF1CB0F6);

  static const Color leagueBg = Color(0xFFFEE2E2);
  static const Color leagueIcon = Color(0xFFEF4444);

  static const Color top3Bg = Color(0xFFEDE9FE);
  static const Color top3Icon = Color(0xFF8B5CF6);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = Get.find<NotificationService>();

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // result bây giờ là kiểu ApiResponse<dynamic>
      final result = await _apiService.getUserProfile();

      if (mounted) {
        setState(() {
          if (result.success && result.data != null) {
            // result.data chính là Map chứa thông tin từ Server
            var responseBody = result.data;

            // Kiểm tra cấu trúc: { "data": { "user": ... } } hoặc { "user": ... }
            var data = responseBody['data'] ?? responseBody;

            if (data['user'] != null && data['user'] is Map) {
              _userData = data['user'];
            } else {
              _userData = data;
            }
          } else {
            // Xử lý khi API trả về success: false
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? "Không thể tải thông tin cá nhân")),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  String _formatJoinDate(String? dateString) {
    if (dateString == null) return "Thành viên mới";
    try {
      final date = DateTime.parse(dateString);
      return "Đã tham gia ${date.month} / ${date.year}";
    } catch (e) {
      return "Thành viên mới";
    }
  }

  List<Map<String, dynamic>> _getAchievements(int streak, int xp, int completedLessons) {
    return [
      {
        'title': 'Lửa rừng',
        'desc': 'Đạt chuỗi 250 ngày streak',
        'current': streak,
        'target': 250,
        'level': 'CẤP 9',
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFFF6B6B),
        'bgColor': const Color(0xFFFEE2E2),
        'progressColor': const Color(0xFFEF4444),
      },
      {
        'title': 'Cao nhân',
        'desc': 'Đạt được 12500 KN',
        'current': xp,
        'target': 12500,
        'level': 'CẤP 9',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFFBBF24),
        'bgColor': const Color(0xFFFEF3C7),
        'progressColor': const Color(0xFFD97706),
      },
      {
        'title': 'Học già',
        'desc': 'Hoàn thành 250 bài học',
        'current': completedLessons,
        'target': 250,
        'level': 'CẤP 7',
        'icon': Icons.menu_book,
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFEF3C7),
        'progressColor': const Color(0xFFD97706),
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: _ProfileColors.background, body: Center(child: CircularProgressIndicator()));
    }

    final String name = _userData['name'] ?? _userData['username'] ?? 'Người dùng';
    final String username = _userData['username'] ?? name; // Username fallback về name nếu ko có


    final String joinDate = _formatJoinDate(_userData['createdAt']);
    final String? avatarUrl = _userData['avatar'];

    int streak = 0;
    if (_userData['streak'] != null) {
      streak = (_userData['streak'] is Map)
          ? (_userData['streak']['count'] ?? 0)
          : int.tryParse(_userData['streak'].toString()) ?? 0;
    }

    int xp = int.tryParse(_userData['xp']?.toString() ?? '0') ?? 0;

    int gems = 0;
    if (_userData['gems'] != null) {
      if (_userData['gems'] is Map) {
        gems = int.tryParse(_userData['gems']['amount']?.toString() ?? '0') ?? 0;
      } else {
        gems = int.tryParse(_userData['gems'].toString()) ?? 0;
      }
    } else if (_userData['gem'] != null) {
      gems = int.tryParse(_userData['gem'].toString()) ?? 0;
    }
    
    print("👤 DEBUG Profile - streak: $streak, xp: $xp, gems: $gems");
    print("👤 DEBUG _userData['gems']: ${_userData['gems']}, type: ${_userData['gems'].runtimeType}");

    int completedLessons = 0;
    if (_userData['progress'] != null && _userData['progress']['completedLessons'] != null) {
      completedLessons = (_userData['progress']['completedLessons'] as List).length;
    }

    final achievements = _getAchievements(streak, xp, completedLessons);

    return Scaffold(
      backgroundColor: _ProfileColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildProfileHeader(name, username, joinDate, avatarUrl),
            const SizedBox(height: 24),

            _buildSectionTitle("Thống kê"),
            const SizedBox(height: 16),
            _buildStatsGrid(streak, xp, gems),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("Thành tích"),
                TextButton(
                    onPressed: (){},
                    child: const Text("XEM TẤT CẢ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                )
              ],
            ),
            const SizedBox(height: 10),
            _buildAchievementsList(achievements),
            _buildSectionTitle("Cài đặt"),
            const SizedBox(height: 10),

            _buildMenuOption(
                Icons.notifications_active,
                "Test Thông báo ngay",
                _testNotification
            ),

            _buildMenuOption(
                Icons.alarm,
                "Bật nhắc nhở học tập (20:00)",
                _enableDailyReminder
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ProfileColors.textPrimary)),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }


  Widget _buildProfileHeader(String name, String username, String joinDate, String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50],
                  image: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(ApiService.getValidImageUrl(avatarUrl)), fit: BoxFit.cover)
                      : null,
                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)))
                    : null,
              ),
              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ProfileColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: const TextStyle(color: _ProfileColors.textSecondary, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: _ProfileColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded( // Thêm Expanded để tránh overflow nếu ngày dài
                          child: Text(
                            joinDate,
                            style: const TextStyle(color: _ProfileColors.textSecondary, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFollowItem(_userData['following']?.toString() ?? "0", "Đang theo dõi"),
              _buildFollowItem(_userData['followers']?.toString() ?? "0", "Người theo dõi"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFollowItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ProfileColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 14, color: _ProfileColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatsGrid(int streak, int xp, int gems) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(Icons.local_fire_department, "$streak", "Ngày streak", _ProfileColors.streakIcon, _ProfileColors.streakBg),
        _buildStatCard(Icons.star, "$xp", "Tổng điểm KN", _ProfileColors.xpIcon, _ProfileColors.xpBg),
        _buildStatCard(Icons.diamond, "$gems", "Đá quý", _ProfileColors.leagueIcon, _ProfileColors.leagueBg),
        _buildStatCard(Icons.emoji_events, "0", "Top 3", _ProfileColors.top3Icon, _ProfileColors.top3Bg),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8), // Tăng khoảng cách chút
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: _ProfileColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Map<String, dynamic>> achievements) {
    return Column(
      children: achievements.map((item) {
        double current = (item['current'] as num).toDouble();
        double target = (item['target'] as num).toDouble();
        double progress = (current / target).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                      colors: [(item['color'] as Color).withValues(alpha: 0.8), item['color']],
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                  ),
                ),
                child: Icon(item['icon'], color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: item['progressColor'],
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${current.toInt()}/${target.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (progress >= 1.0)
                          const Text("HOÀN THÀNH", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Đăng xuất?"),
            content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy")),
              TextButton(onPressed: () {
                Navigator.pop(ctx);
                _performLogout();
              },
                  child: const Text(
                      "Đăng xuất", style: TextStyle(color: Colors.red))),
            ],
          ),
    );
  }
    void _testNotification() {
      _notificationService.showNotification(
        id: 1,
        title: "Xin chào!",
        body: "Đây là thông báo từ English Master.",
      );
    }

    void _enableDailyReminder() async {
      await _notificationService.requestPermissions(); // Xin quyền trước
      await _notificationService.scheduleDailyReminder();

      Get.snackbar(
          "Thành công",
          "Đã đặt lịch nhắc học vào 20:00 hàng ngày!",
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          snackPosition: SnackPosition.TOP
      );
    }

}
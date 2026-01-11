import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Gọi API - kết quả trả về là ApiResponse
    final result = await _apiService.getLeaderboard();

    if (mounted) {
      setState(() {
        if (result.success) {
          // Nếu thành công, lấy dữ liệu từ result.data (là List<dynamic>)
          _users = result.data ?? [];
        } else {
          // Nếu thất bại, bạn có thể hiển thị thông báo lỗi từ server
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "Không thể tải bảng xếp hạng"),
              backgroundColor: Colors.red,
            ),
          );
          _users = []; // Đảm bảo danh sách rỗng nếu lỗi
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5D1),
      appBar: AppBar(
        title: const Text(
          "Bảng Xếp Hạng",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          // ✅ HIỂN THỊ KHI KHÔNG CÓ DỮ LIỆU
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có bảng xếp hạng",
                    style: TextStyle(color: Colors.brown, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text("Tải lại"),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_users.isNotEmpty) _buildTop3(),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _users.length > 3 ? _users.length - 3 : 0,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final user = _users[index + 3];
                        return ListTile(
                          leading: SizedBox(
                            width: 75, // Tăng từ 70 lên 75 để tránh overflow
                            child: Row(
                              children: [
                                Text(
                                  "#${index + 4}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[200],
                                  child: ClipOval(
                                    // Dùng ClipOval để đảm bảo ảnh bên trong được bo tròn
                                    child: (user['avatar'] != null)
                                        ? Image.network(
                                            ApiService.getValidImageUrl(
                                              user['avatar'],
                                            ),
                                            fit: BoxFit.cover,
                                            width: 36, // width = 2 * radius
                                            height: 36, // height = 2 * radius
                                            // Xử lý khi có lỗi tải ảnh
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      user['name'][0],
                                                    ),
                                                  );
                                                },
                                          )
                                        : Center(
                                            child: Text(user['name'][0]),
                                          ), // Hiển thị chữ cái đầu nếu không có avatar
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            user['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            "${user['xp']} XP",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTop3() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_users.length >= 2)
            _buildPodiumUser(_users[1], 2, 90, Colors.grey),
          if (_users.isNotEmpty)
            _buildPodiumUser(_users[0], 1, 110, Colors.amber),
          if (_users.length >= 3)
            _buildPodiumUser(_users[2], 3, 90, Colors.brown.shade300),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(dynamic user, int rank, double size, Color color) {
    final avatarUrl = user['avatar'] != null
        ? ApiService.getValidImageUrl(user['avatar'])
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200], // Màu nền mặc định
            child: ClipOval(
              // Dùng ClipOval để đảm bảo ảnh bên trong được bo tròn
              child:
                  (avatarUrl
                      .isNotEmpty) // Chỉ tạo Image.network nếu URL không rỗng
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      width: 60, // width = 2 * radius
                      height: 60, // height = 2 * radius
                      // Xử lý khi có lỗi tải ảnh (404 hoặc lỗi mạng khác)
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            user['name'][0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        );
                      },
                      // (Tùy chọn) Hiển thị loading indicator khi đang tải
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    )
                  // Hiển thị chữ cái đầu nếu avatarUrl là rỗng
                  : Center(
                      child: Text(
                        user['name'][0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            "${user['xp']} XP",
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: size * 0.8,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

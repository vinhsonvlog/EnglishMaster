import 'dart:math';
import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';
// ✅ SỬA 1: Import màn hình bài học chi tiết
import 'package:englishmaster/screens/lesson/lesson_screen.dart';

// Enum trạng thái bài học
enum LessonStatus { locked, unlocked, current, completed }

// Bảng màu giao diện
class _AppColors {
  static const Color green = Color(0xFF58CC02);
  static const Color greenShadow = Color(0xFF46A302);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldShadow = Color(0xFFCC8800);
  static const Color grey = Color(0xFFE5E5E5);
  static const Color greyShadow = Color(0xFFAFAFAF);
  static const Color lockedIcon = Color(0xFFAFAFAF);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF4B4B4B);
  static const Color background = Colors.white;
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // Tạo ScrollController riêng để tránh lỗi xung đột cuộn
  final ScrollController _scrollController = ScrollController();

  late Future<List<dynamic>> _lessonsFuture;

  // Animation cho hiệu ứng "nhịp tim" của bài đang học
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _apiService.getLessons();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Lặp lại liên tục

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: _buildAppBar(),
      body: FutureBuilder<List<dynamic>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi kết nối: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có bài học nào.'));
          }

          // 1. Lấy dữ liệu gốc
          final allLessons = snapshot.data!;

          // 2. Sắp xếp theo thứ tự (order)
          allLessons.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

          // 3. LỌC DỮ LIỆU
          final unit1Lessons = allLessons.where((lesson) {
            final unitTitle = lesson['unit'] is Map ? lesson['unit']['title'] : '';
            return unitTitle.toString().contains("1") || unitTitle.toString().toLowerCase().contains("unit 1");
          }).toList();

          final displayLessons = unit1Lessons.isNotEmpty ? unit1Lessons : allLessons.take(10).toList();

          // Tách logic lấy tên Unit ra ngoài để an toàn hơn
          String currentUnitTitle = "Unit 1";
          if (displayLessons.isNotEmpty) {
            final firstLesson = displayLessons[0];
            if (firstLesson['unit'] != null && firstLesson['unit'] is Map) {
              currentUnitTitle = firstLesson['unit']['title'] ?? "Unit 1";
            }
          }

          final completedCount = 2;
          final currentIdx = 2;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildUnitHeader(currentUnitTitle),
                const SizedBox(height: 30),

                _buildLessonPath(displayLessons, completedCount, currentIdx),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.flag_circle, color: Colors.grey, size: 36),
          _buildStatItem(Icons.local_fire_department, Colors.orange, "3"),
          _buildStatItem(Icons.diamond, Colors.blue, "450"),
          _buildStatItem(Icons.favorite, Colors.red, "5"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildUnitHeader(String unitTitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: _AppColors.greenShadow, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unitTitle.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                const Text("Cơ bản về Tiếng Anh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _AppColors.greenShadow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Icon(Icons.menu_book, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildLessonPath(List<dynamic> lessons, int completedCount, int currentIdx) {
    const double nodeHeight = 110.0;

    return SizedBox(
      height: lessons.length * nodeHeight + 50,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(
                itemCount: lessons.length,
                rowHeight: nodeHeight,
                offsetX: 70.0,
              ),
            ),
          ),

          ...List.generate(lessons.length, (index) {
            final lesson = lessons[index];

            LessonStatus status = LessonStatus.locked;
            if (index < completedCount) status = LessonStatus.completed;
            else if (index == currentIdx) status = LessonStatus.current;
            else if (index == completedCount && currentIdx == -1) status = LessonStatus.unlocked;

            final double offsetX = 70.0;
            double dx = sin(index * pi / 2) * offsetX;

            return Positioned(
              top: index * nodeHeight,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: _buildLessonNode(lesson, status),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLessonNode(dynamic lesson, LessonStatus status) {
    Color bgColor;
    Color shadowColor;
    double size = 70;
    Widget icon;
    bool showCrown = false;

    switch (status) {
      case LessonStatus.completed:
        bgColor = _AppColors.gold;
        shadowColor = _AppColors.goldShadow;
        icon = const Icon(Icons.check, size: 35, color: Colors.white);
        showCrown = true;
        break;
      case LessonStatus.current:
      case LessonStatus.unlocked:
        bgColor = _AppColors.green;
        shadowColor = _AppColors.greenShadow;
        icon = const Icon(Icons.star, size: 35, color: Colors.white);
        break;
      case LessonStatus.locked:
      default:
        bgColor = _AppColors.grey;
        shadowColor = _AppColors.greyShadow;
        icon = const Icon(Icons.lock, size: 30, color: _AppColors.lockedIcon);
        break;
    }

    Widget button = GestureDetector(
      onTap: () {
        if (status != LessonStatus.locked) {
          // ✅ SỬA 2: Điều hướng sang LessonScreen (Màn hình làm bài tập)
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => LessonScreen(
                lessonId: lesson['_id'] ?? 'default',
              )
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Hoàn thành bài trước để mở khóa!"), duration: Duration(seconds: 1))
          );
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: status == LessonStatus.current
              ? Border.all(color: Colors.white, width: 4)
              : null,
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 6), blurRadius: 0),
            if (status == LessonStatus.current)
              BoxShadow(color: _AppColors.green.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Center(child: icon),
      ),
    );

    if (status == LessonStatus.current) {
      button = ScaleTransition(scale: _scaleAnim, child: button);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown)
          Transform.translate(
            offset: const Offset(20, 10),
            child: const Icon(Icons.emoji_events, color: Colors.orange, size: 24),
          ),

        if (status == LessonStatus.current)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _AppColors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("BẮT ĐẦU!", style: TextStyle(color: _AppColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

        button,

        const SizedBox(height: 8),
        Text(
          lesson['title'] ?? "Bài học",
          style: TextStyle(
              color: status == LessonStatus.locked ? _AppColors.greyShadow : _AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  final int itemCount;
  final double rowHeight;
  final double offsetX;

  PathPainter({required this.itemCount, required this.rowHeight, required this.offsetX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _AppColors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    for (int i = 0; i < itemCount - 1; i++) {
      double startX = centerX + (sin(i * pi / 2) * offsetX);
      double startY = (i * rowHeight) + 35;

      double endX = centerX + (sin((i + 1) * pi / 2) * offsetX);
      double endY = ((i + 1) * rowHeight) + 35;

      Path path = Path();
      path.moveTo(startX, startY);

      path.cubicTo(startX, startY + (rowHeight/2), endX, endY - (rowHeight/2), endX, endY);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
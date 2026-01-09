import 'dart:math';
import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/lesson/lesson_screen.dart';

enum LessonStatus { locked, unlocked, current, completed }

class _LearnStyles {
  static const Color unit1Color = Color(0xFF58CC02);
  static const Color unit1Shadow = Color(0xFF46A302);

  static const Color lockedGray = Color(0xFFE5E5E5);
  static const Color lockedShadow = Color(0xFFC7C7C7); // Màu shadow cho nút khóa
  static const Color lockedIcon = Color(0xFFAFAFAF);

  static const Color gold = Color(0xFFFFD700);
  static const Color goldShadow = Color(0xFFCC8800);

  static const Color background = Colors.white;

  static const LinearGradient unit1Gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF58CC02), Color(0xFF46A302)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  static const LinearGradient lockedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE5E5E5), Color(0xFFD1D5DB)],
  );
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  bool _isLoading = true;

  List<Map<String, dynamic>> _units = [];
  Map<String, dynamic> _userProgress = {};
  Map<String, dynamic> _userProfile = {};
  String? _calculatedCurrentLessonId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getLessons(),      // [0] ApiResponse<List<dynamic>>
        _apiService.getUserProgress(), // [1] ApiResponse<Map<String, dynamic>>
        _apiService.getUserProfile(),  // [2] ApiResponse<Map<String, dynamic>>
      ]);

      if (!mounted) return;

      var rawLessons = (results[0].data as List<dynamic>?) ?? [];
      var progress = (results[1].data as Map<String, dynamic>?) ?? {'completedLessons': [], 'currentLesson': null};
      var profileData = (results[2].data as Map<String, dynamic>?) ?? {};
      
      print("📊 DEBUG profileData: $profileData");
      
      Map<String, dynamic> profile;
      if (profileData.containsKey('data') && profileData['data'] is Map) {
        var nestedData = profileData['data'] as Map<String, dynamic>;
        if (nestedData.containsKey('user') && nestedData['user'] is Map) {
          profile = nestedData['user'] as Map<String, dynamic>;
          print("📊 DEBUG profile từ data.user: $profile");
        } else {
          profile = nestedData;
          print("📊 DEBUG profile từ data: $profile");
        }
      } else if (profileData.containsKey('user') && profileData['user'] is Map) {
        profile = profileData['user'] as Map<String, dynamic>;
        print("📊 DEBUG profile từ user: $profile");
      } else {
        profile = profileData;
        print("📊 DEBUG profile trực tiếp: $profile");
      }
      
      print("📊 DEBUG streak: ${profile['streak']}, gems: ${profile['gems']}, xp: ${profile['xp']}");
      
      rawLessons.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      var filteredLessons = rawLessons.where((lesson) {
        String unitTitle = "";
        if (lesson['unit'] != null && lesson['unit'] is Map) {
          unitTitle = lesson['unit']['title']?.toString() ?? "";
        } else {
          unitTitle = "Unit ${lesson['unit'] ?? 1}";
        }
        return unitTitle.contains("1");
      }).toList();

      List<dynamic> completedIds = progress['completedLessons'] ?? [];
      String? currentId = progress['currentLesson'];

      if (currentId == null || currentId.isEmpty) {
        for (var lesson in filteredLessons) {
          if (!completedIds.contains(lesson['_id'])) {
            currentId = lesson['_id'];
            break;
          }
        }
      }

      Map<String, dynamic> unit1 = {
        'id': 'unit1',
        'title': 'Unit 1',
        'description': 'Cơ bản',
        'order': 1,
        'lessons': filteredLessons,
        'color': _LearnStyles.unit1Color,
        'shadowColor': _LearnStyles.unit1Shadow,
      };

      setState(() {
        _units = [unit1]; // Chỉ hiển thị 1 Unit
        _userProgress = progress;
        _userProfile = profile;
        _calculatedCurrentLessonId = currentId;
        _isLoading = false;
      });

    } catch (e) {
      print("Lỗi tải dữ liệu LearnScreen: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _getLessonIcon(String type, Color color, double size) {
    IconData iconData;
    switch (type) {
      case 'grammar': iconData = Icons.star; break; // Star
      case 'practice': iconData = Icons.fitness_center; break; // FitnessCenter
      case 'story': iconData = Icons.menu_book; break; // MenuBook
      case 'conversation': iconData = Icons.chat; break; // Chat
      case 'trophy': iconData = Icons.emoji_events; break; // EmojiEvents
      case 'vocabulary':
      default: iconData = Icons.local_library; // LocalLibrary
    }
    return Icon(iconData, color: color, size: size);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    final streak = (_userProfile['streak'] is Map) 
        ? (_userProfile['streak']['count'] ?? 0)
        : (_userProfile['streak'] ?? 0);
    
    final gems = (_userProfile['gems'] is Map)
        ? (_userProfile['gems']['amount'] ?? 0)
        : (int.tryParse(_userProfile['gems']?.toString() ?? '') ?? 
           int.tryParse(_userProfile['gem']?.toString() ?? '') ?? 0);
    
    final xp = int.tryParse(_userProfile['xp']?.toString() ?? '') ?? 0;
    
    return Scaffold(
      backgroundColor: _LearnStyles.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/US.png', width: 32, errorBuilder: (c,e,s) => const Icon(Icons.flag, color: Colors.grey)),
            _buildStatItem(Icons.local_fire_department, Colors.orange, "$streak"),
            _buildStatItem(Icons.diamond, Colors.blue, "$gems"),
            _buildStatItem(Icons.flash_on, Colors.amber, "$xp"),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: Colors.grey[200], height: 2),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _units.isEmpty
            ? const Center(child: Text("Không tìm thấy bài học Unit 1.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: _units.length,
          itemBuilder: (context, index) {
            return _buildUnitSection(_units[index]);
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _buildUnitSection(Map<String, dynamic> unit) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: unit['color'],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: unit['shadowColor'], offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "PHẦN ${unit['order']}, CỬA 1-10",
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0)
                    ),
                    const SizedBox(height: 6),
                    Text(
                        unit['description'],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("HƯỚNG DẪN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            "Hãy bắt đầu với những từ và cụm từ đơn giản!",
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ),

        _buildLessonMap(unit['lessons']),
      ],
    );
  }

  Widget _buildLessonMap(List<dynamic> lessons) {
    const double rowHeight = 130.0;

    return SizedBox(
      height: lessons.length * rowHeight + 50,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(
                itemCount: lessons.length,
                rowHeight: rowHeight,
                offsetX: 70.0,
              ),
            ),
          ),
          ...List.generate(lessons.length, (index) {
            final lesson = lessons[index];
            final completedIds = _userProgress['completedLessons'] ?? [];
            final bool isCompleted = completedIds.contains(lesson['_id']);
            final bool isCurrent = lesson['_id'] == _calculatedCurrentLessonId;

            bool isLocked = false;
            if (index > 0) {
              final prevLesson = lessons[index - 1];
              final isPrevCompleted = completedIds.contains(prevLesson['_id']);
              isLocked = !isPrevCompleted && !isCurrent && !isCompleted;
            }

            final double offsetX = 70.0 * sin(index * pi / 2);

            return Positioned(
              top: index * rowHeight,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(offsetX, 0),
                child: Center(
                  child: _buildLessonNode(lesson, isCompleted, isCurrent, isLocked, index % 2 == 0),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLessonNode(Map<String, dynamic> lesson, bool isCompleted, bool isCurrent, bool isLocked, bool isLeft) {
    Gradient bgGradient = _LearnStyles.lockedGradient;
    Color shadowColor = _LearnStyles.lockedShadow;
    Color iconColor = _LearnStyles.lockedIcon;
    double size = 70;

    if (isCompleted) {
      bgGradient = _LearnStyles.goldGradient;
      shadowColor = _LearnStyles.goldShadow;
      iconColor = Colors.white;
    } else if (isCurrent) {
      bgGradient = _LearnStyles.unit1Gradient;
      shadowColor = _LearnStyles.unit1Shadow;
      iconColor = Colors.white;
    }

    Widget button = GestureDetector(
      onTap: () async {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Hoàn thành bài học trước để mở khóa!"), duration: Duration(seconds: 1)),
          );
        } else {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LessonScreen(lessonId: lesson['_id']))
          );

          if (result == true) {
            print(" Phát hiện bài học hoàn thành, đang tải lại dữ liệu...");
            _fetchData();
          }
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: bgGradient, // Dùng Gradient để giống nút 3D
          shape: BoxShape.circle,
          border: isCurrent ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: [
            BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 6), // Đổ bóng xuống dưới
                blurRadius: 0 // Bóng cứng (không mờ) để tạo hiệu ứng 3D
            ),
            if (isCurrent)
              BoxShadow(
                  color: _LearnStyles.unit1Color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2
              )
          ],
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _getLessonIcon(lesson['type'] ?? 'lesson', iconColor, 32),

              if (isCompleted)
                Positioned(
                  right: 10,
                  bottom: 5,
                  child: Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.orange, size: 14)
                  ),
                )
            ],
          ),
        ),
      ),
    );

    if (isCurrent) {
      button = ScaleTransition(scale: _scaleAnim, child: button);
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (isCurrent)
          Positioned(
            left: isLeft ? 100 : null,
            right: isLeft ? null : 100,
            bottom: 25,
            child: Image.asset(
              'assets/images/LinhThuTini.gif',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (c,e,s)=>const SizedBox(),
            ),
          ),

        Column(
          children: [
            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _LearnStyles.unit1Shadow),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0,2), blurRadius: 4)]
                ),
                child: const Text("BẮT ĐẦU", style: TextStyle(color: _LearnStyles.unit1Color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),

            button,

            const SizedBox(height: 8),
            Text(
              lesson['title'] ?? 'Bài học',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isLocked ? Colors.grey : Colors.black87
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      ..color = _LearnStyles.lockedGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 // Đường đi dày hơn chút
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    for (int i = 0; i < itemCount - 1; i++) {
      double startX = centerX + (sin(i * pi / 2) * offsetX);
      double startY = (i * rowHeight) + 35;

      double endX = centerX + (sin((i + 1) * pi / 2) * offsetX);
      double endY = ((i + 1) * rowHeight) + 35;

      Path path = Path();
      path.moveTo(startX, startY);

      path.cubicTo(
          startX, startY + (rowHeight / 2),
          endX, endY - (rowHeight / 2),
          endX, endY
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

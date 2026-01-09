import 'dart:math';
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/models/flashcard.dart';
import 'package:englishmaster/services/api_service.dart';
import '../../models/api_response.dart';

class QuizScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const QuizScreen({super.key, required this.deckId, required this.deckTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  late Future<ApiResponse<List<Flashcard>>> _flashcardsFuture;

  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flashcardsFuture = _apiService.getFlashcardsByDeck(widget.deckId);
  }

  void _nextCard(int totalLength) {
    if (_currentIndex < totalLength - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Chúc mừng! 🎉", textAlign: TextAlign.center),
        content: const Text("Bạn đã hoàn thành ôn tập bộ thẻ này!", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Hoàn thành", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.deckTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: FutureBuilder<ApiResponse<List<Flashcard>>>(
            future: _flashcardsFuture,
            builder: (context, snapshot) {
              // Kiểm tra thêm điều kiện .success và lấy dữ liệu từ .data
              if (!snapshot.hasData || !snapshot.data!.success || snapshot.data!.data!.isEmpty)
                return const SizedBox();
              double progress = (_currentIndex + 1) / snapshot.data!.data!.length; // Sửa snapshot.data!.data!
              return LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<ApiResponse<List<Flashcard>>>(
        future: _flashcardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // Kiểm tra lỗi kết nối hoặc lỗi từ Server
          if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.success)) {
            String errorMsg = snapshot.data?.message ?? snapshot.error.toString();
            return Center(child: Text("Lỗi: $errorMsg"));
          }

          // Kiểm tra nếu không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.data == null || snapshot.data!.data!.isEmpty) {
            return _buildEmptyState();
          }

          // LẤY DANH SÁCH THẺ TỪ .data!.data!
          final flashcards = snapshot.data!.data!;
          final currentCard = flashcards[_currentIndex];

          return Column(
            children: [
              // 1. KHU VỰC THẺ (Flashcard Area)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFlipped = !_isFlipped;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
                        return AnimatedBuilder(
                          animation: rotateAnim,
                          child: child,
                          builder: (context, child) {
                            final isUnder = (ValueKey(_isFlipped) != child!.key);
                            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                            tilt *= isUnder ? -1.0 : 1.0;
                            final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
                            return Transform(
                              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                              alignment: Alignment.center,
                              child: child,
                            );
                          },
                        );
                      },
                      child: _isFlipped
                          ? _buildCardSide(currentCard, isBack: true)
                          : _buildCardSide(currentCard, isBack: false),
                    ),
                  ),
                ),
              ),

              // 2. THANH ĐIỀU HƯỚNG (Navigation Bar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút Trước (Previous)
                    IconButton.filled(
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.all(12),
                        shadowColor: Colors.black12,
                        elevation: 2,
                      ),
                    ),

                    // Số trang (Counter)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_currentIndex + 1} / ${flashcards.length}",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700
                        ),
                      ),
                    ),

                    // Nút Sau (Next)
                    IconButton.filled(
                      onPressed: _currentIndex < flashcards.length - 1 ? () => _nextCard(flashcards.length) : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.all(12),
                        shadowColor: Colors.black12,
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. NÚT ĐÁNH GIÁ (Grading Buttons)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(flashcards.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("CHƯA THUỘC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(flashcards.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("ĐÃ THUỘC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Chưa có thẻ nào trong bộ này",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Quay lại", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildCardSide(Flashcard card, {required bool isBack}) {
    String? displayImage = isBack ? null : card.imageUrl;
    String text = isBack ? card.definition : card.term;
    String label = isBack ? "Định nghĩa" : "Thuật ngữ";
    Color bgColor = Colors.white;
    Color textColor = isBack ? const Color(0xFF2D3436) : AppColors.primary;

    // Tạo shadow nhẹ nhàng
    List<BoxShadow> shadows = [
      BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 8), blurRadius: 16)
    ];

    Border? border = isBack ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2) : null;

    return Container(
      key: ValueKey(isBack),
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: border,
        boxShadow: shadows,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label (Thuật ngữ / Định nghĩa)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBack ? Colors.grey.shade100 : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                  color: isBack ? Colors.grey.shade600 : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Ảnh minh họa (chỉ mặt trước)
          if (displayImage != null && displayImage.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiService.getValidImageUrl(displayImage),
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Nội dung text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.3
              ),
            ),
          ),

          // Hướng dẫn chạm (chỉ mặt trước)
          if (!isBack) ...[
            const SizedBox(height: 40),
            Icon(Icons.touch_app_rounded, color: Colors.grey.shade300, size: 28),
            const SizedBox(height: 8),
            Text("Chạm để lật thẻ", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ]
        ],
      ),
    );
  }
}
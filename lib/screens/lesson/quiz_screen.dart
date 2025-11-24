import 'dart:math'; // Để xoay thẻ
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/models/flashcard.dart';
import 'package:englishmaster/services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const QuizScreen({super.key, required this.deckId, required this.deckTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Flashcard>> _flashcardsFuture;

  // Quản lý trạng thái học
  int _currentIndex = 0;
  bool _isFlipped = false; // Trạng thái lật mặt sau

  @override
  void initState() {
    super.initState();
    _flashcardsFuture = _apiService.getFlashcardsByDeck(widget.deckId);
  }

  void _nextCard(int totalLength) {
    if (_currentIndex < totalLength - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false; // Reset về mặt trước
      });
    } else {
      // Hoàn thành bài học
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Chúc mừng! 🎉"),
        content: const Text("Bạn đã ôn tập xong bộ thẻ này."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(context); // Quay về màn hình danh sách
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        // Thanh tiến trình (Progress Bar)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: FutureBuilder<List<Flashcard>>(
            future: _flashcardsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              double progress = (_currentIndex + 1) / snapshot.data!.length;
              return LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<Flashcard>>(
        future: _flashcardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bộ thẻ này chưa có từ vựng nào."));
          }

          final flashcards = snapshot.data!;
          final currentCard = flashcards[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Khu vực thẻ Flashcard
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFlipped = !_isFlipped;
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
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
                          ? _buildCardSide(currentCard.definition, "Định nghĩa", Colors.blue.shade50, isBack: true)
                          : _buildCardSide(currentCard.term, "Thuật ngữ", Colors.white, isBack: false),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Các nút điều hướng
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(flashcards.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("CHƯA THUỘC", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _nextCard(flashcards.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("ĐÃ THUỘC", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(String text, String label, Color color, {required bool isBack}) {
    return Container(
      key: ValueKey(isBack),
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 6),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isBack ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (!isBack) ...[
            const SizedBox(height: 30),
            const Icon(Icons.touch_app, color: Colors.grey),
            const Text("Chạm để lật", style: TextStyle(color: Colors.grey)),
          ]
        ],
      ),
    );
  }
}
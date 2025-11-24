import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/lesson/quiz_screen.dart'; // Nhớ import file mới tạo

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _decksFuture = _apiService.getDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho từ vựng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                  TextButton(onPressed: () {
                    setState(() { _decksFuture = _apiService.getDecks(); });
                  }, child: const Text("Thử lại"))
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final decks = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85, // Thẻ cao hơn một chút để chứa nút bấm
            ),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              return _buildDeckCard(decks[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở màn hình tạo bộ thẻ mới
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Bạn chưa có bộ thẻ nào", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDeckCard(dynamic deck) {
    // Random màu cho đẹp nếu backend không trả về màu
    final List<Color> cardColors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.teal];
    final color = cardColors[deck['title'].hashCode % cardColors.length];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // TODO: Điều hướng vào xem chi tiết flashcard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                deckId: deck['_id'] ?? 'default_id', // Lấy ID từ MongoDB
                deckTitle: deck['title'] ?? 'Flashcards',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.style, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                deck['title'] ?? 'Không tên',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${deck['flashcardCount'] ?? 0} thẻ',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // Nút học nhanh
              Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 16,
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
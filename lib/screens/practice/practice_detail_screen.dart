import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';

class PracticeDetailScreen extends StatefulWidget {
  final String practiceId;
  final String title;

  const PracticeDetailScreen({super.key, required this.practiceId, required this.title});

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _apiService.getPracticeExerciseById(widget.practiceId);
      if (mounted) {
        setState(() {
          _questions = data['questions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
          ? const Center(child: Text("Bài tập này chưa có câu hỏi."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final q = _questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Câu ${index + 1}: ${q['question'] ?? 'Câu hỏi...'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  // Hiển thị đáp án (Mock UI - bạn có thể phát triển thêm logic chọn đáp án)
                  if (q['options'] != null)
                    ...((q['options'] as List).map((opt) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text("• ${opt['text'] ?? opt}"),
                    ))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
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
  dynamic _practiceData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await _apiService.getPracticeExerciseById(widget.practiceId);
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _practiceData = response.data;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error?.message ?? "Lỗi tải dữ liệu"))
          );
        }
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
          : _practiceData == null
          ? const Center(child: Text("Không thể tải dữ liệu bài tập."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _practiceData['question'] ?? 'Câu hỏi...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (_practiceData['type'] == 'multiple_choice' && _practiceData['choices'] != null)
                  ...(_practiceData['choices'] as List).asMap().entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${String.fromCharCode(65 + entry.key)}. ${entry.value}'),
                      ),
                    ),
                  ),
                if (_practiceData['type'] == 'fill_blank')
                  Text(
                    'Loại: Điền vào chỗ trống',
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Giải thích:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _practiceData['explanation'] ?? 'Chưa có giải thích',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (_practiceData['correctAnswer'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Đáp án: ${_practiceData['correctAnswer']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
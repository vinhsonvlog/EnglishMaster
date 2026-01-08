import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/practice/practice_detail_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _getItemTitle(dynamic item) {
    if (item['question'] != null && item['question'].toString().isNotEmpty) return item['question'];
    if (item['title'] != null && item['title'].toString().isNotEmpty) return item['title'];
    if (item['name'] != null && item['name'].toString().isNotEmpty) return item['name'];
    if (item['topic'] != null && item['topic'].toString().isNotEmpty) return item['topic'];
    return "Bài tập #${item['_id'].toString().substring(0, 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Luyện tập & Kiểm tra", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Luyện tập"),
            Tab(text: "Bài kiểm tra"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_apiService.getPracticeExercises().then((r) => r.data ?? []), isTest: false),
          _buildList(_apiService.getTests().then((r) => r.data ?? []), isTest: true),
        ],
      ),
    );
  }

  Widget _buildList(Future<List<dynamic>> future, {required bool isTest}) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isTest ? "Chưa có bài kiểm tra nào" : "Chưa có bài luyện tập nào"));
        }

        final items = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final title = _getItemTitle(item); // ✅ SỬA LỖI KHÔNG TÊN

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTest ? Colors.red[50] : Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTest ? Icons.assignment : Icons.fitness_center,
                      color: isTest ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          item['explanation'] ?? item['description'] ?? 'Không có mô tả', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 13), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!isTest) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PracticeDetailScreen(practiceId: item['_id'], title: title))
                        );
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PracticeDetailScreen(practiceId: item['_id'], title: title))
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTest ? Colors.red : Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("Bắt đầu", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
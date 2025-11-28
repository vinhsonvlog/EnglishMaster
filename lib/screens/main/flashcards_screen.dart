import 'dart:math';
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/services/api_service.dart';
import 'package:englishmaster/screens/lesson/quiz_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _decksFuture;

  List<dynamic> _allDecks = [];
  List<dynamic> _filteredDecks = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  void _loadDecks() {
    setState(() {
      _decksFuture = _apiService.getDecks().then((data) {
        _allDecks = data;
        _filteredDecks = data;
        return data;
      });
    });
  }

  void _filterDecks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDecks = _allDecks;
      } else {
        _filteredDecks = _allDecks.where((deck) {
          final title = (deck['title'] ?? '').toString().toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<dynamic>>(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterDecks,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm chủ đề...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              if (_filteredDecks.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _buildModernDeckCard(_filteredDecks[index], index);
                      },
                      childCount: _filteredDecks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100.0,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: const Text(
          'Kho Từ Vựng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.layers_clear_outlined, size: 60, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 16),
          const Text(
            "Không tìm thấy bộ thẻ nào",
            style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text("Lỗi: $error", textAlign: TextAlign.center),
            TextButton(onPressed: _loadDecks, child: const Text("Thử lại"))
          ],
        ),
      ),
    );
  }

  Widget _buildModernDeckCard(dynamic deck, int index) {
    final int hash = deck['_id'].toString().hashCode;
    final List<Color> accentColors = [
      const Color(0xFF6C63FF), const Color(0xFFFF6584),
      const Color(0xFF38B6FF), const Color(0xFFFFBC2F), const Color(0xFF00D2BA),
    ];
    final Color themeColor = accentColors[hash.abs() % accentColors.length];
    final int totalCards = deck['totalCards'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // === LOGIC KIỂM TRA 0 THẺ TẠI ĐÂY ===
            if (totalCards == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Bộ thẻ này chưa có từ vựng nào!'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.orange.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            // =====================================

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  deckId: deck['_id'] ?? '',
                  deckTitle: deck['title'] ?? 'Flashcards',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.school_rounded, color: themeColor, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  deck['title'] ?? 'Chưa đặt tên',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.style, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('$totalCards thẻ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
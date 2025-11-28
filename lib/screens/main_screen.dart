import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/screens/main/learn_screen.dart';
import 'package:englishmaster/screens/main/flashcards_screen.dart'; // ✅ Đã import màn hình Flashcard mới
import 'package:englishmaster/screens/main/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình
  final List<Widget> _screens = [
    const LearnScreen(),      // 0: Học
    const FlashcardsScreen(), // 1: Thẻ từ (Đã cập nhật)
    const Scaffold(body: Center(child: Text("Xếp hạng (Coming Soon)"))), // 2
    const Scaffold(body: Center(child: Text("Cửa hàng (Coming Soon)"))), // 3
    const ProfileScreen(),    // 4: Hồ sơ
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Cố định để hiện đủ 5 icon
          backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Học'),
            BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Thẻ từ'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Xếp hạng'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cửa hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }
}
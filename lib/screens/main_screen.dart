import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/screens/main/learn_screen.dart';
import 'package:englishmaster/screens/main/flashcards_screen.dart';
import 'package:englishmaster/screens/main/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với menu
  final List<Widget> _screens = [
    const LearnScreen(),      // Trang Học
    const FlashcardsScreen(), // Trang Thẻ từ
    const Scaffold(body: Center(child: Text("Xếp hạng"))), // Leaderboard
    const Scaffold(body: Center(child: Text("Cửa hàng"))), // Shop
    const ProfileScreen(),    // Hồ sơ
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Học'),
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Thẻ từ'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Xếp hạng'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cửa hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:englishmaster/config/colors.dart';
import 'package:englishmaster/screens/main/learn_screen.dart';
import 'package:englishmaster/screens/main/flashcards_screen.dart';
import 'package:englishmaster/screens/main/profile_screen.dart';
import 'package:englishmaster/screens/leaderboard/leaderboard_screen.dart';
import 'package:englishmaster/screens/shop/shop_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LearnScreen(),        // 0: Học (Home)
    const FlashcardsScreen(),   // 1: Thẻ từ (Flashcards)
    const LeaderboardScreen(),  // 2: Xếp hạng (Leaderboard)
    const ShopScreen(),         // 3: Cửa hàng (Shop)
    const ProfileScreen(),      // 4: Hồ sơ (Profile)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Quan trọng: fixed để hiện 5 icon đều nhau
          backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Học',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Thẻ từ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Xếp hạng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Cửa hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary, // Màu xanh chủ đạo
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }
}
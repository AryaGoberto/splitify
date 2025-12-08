import 'package:flutter/material.dart';
import 'package:splitify/page/history_screen.dart';
import 'package:splitify/page/home_screen.dart';
import 'package:splitify/page/scan_struk_page.dart';
import 'notifications_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  // Halaman sesuai tab
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    ScanStrukPage(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(child: _pages[_selectedIndex]),
      // Bottom bar dengan notch untuk FAB
      bottomNavigationBar: SafeArea(
        top: true,
        child: BottomAppBar(
          color: darkBlue,
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: 60, // tinggi fix, aman di semua hp
            child: Row(
              children: [
                // Bagian kiri (Home)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                      ),
                      const SizedBox(width: 50),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history,
                        label: 'History',
                      ),
                      const SizedBox(width: 50),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.camera_alt_rounded,
                        activeIcon: Icons.camera_alt_rounded,
                        label: 'Scan',
                      ),
                      const SizedBox(width: 50),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: 'Notif',
                      ),
                      const SizedBox(width: 50),

                      _buildNavItem(
                        index: 4,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    const Color primaryColor = Color(0xFF3B5BFF);
    final bool isActive = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? primaryColor : Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }
}
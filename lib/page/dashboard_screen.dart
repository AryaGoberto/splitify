import 'package:flutter/material.dart';
import 'package:splitify/page/history_screen.dart';
import 'package:splitify/page/home_page.dart';
import 'package:splitify/page/scan_struk_page.dart';
import './notifications_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Home, 1 = Notif, 2 = Profil
  int _selectedIndex = 0;

  // Halaman sesuai tab
  static const List<Widget> _pages = <Widget>[
    HomeTabPage(),
    HistoryScreen(),
    NotificationsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // FAB → halaman scan struk
  void _navigateToScanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanStrukPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,

      body: SafeArea(child: _pages[_selectedIndex]),

      // FAB bulat di tengah, nembus BottomAppBar
      floatingActionButton: FloatingActionButton(
        heroTag: 'scan-fab',
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        onPressed: _navigateToScanPage,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom bar dengan notch untuk FAB
      bottomNavigationBar: SafeArea(
        top: true,
        child: BottomAppBar(
          color: darkBlue,
          shape: const CircularNotchedRectangle(),
          // notchMargin: 6.0,
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
                    ],
                  ),
                ),

                // ruang untuk FAB di tengah
                const SizedBox(width: 50),

                // Bagian kanan (Notif & Profil)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem(
                        index: 2,
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: 'Notif',
                      ),
                      const SizedBox(width: 50),

                      _buildNavItem(
                        index: 3,
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Halaman Profil", style: TextStyle(color: Colors.white)),
    );
  }
}

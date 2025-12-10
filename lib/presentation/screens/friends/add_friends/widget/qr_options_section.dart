// lib/presentation/screens/friends/widgets/qr_options_section.dart

import 'package:flutter/material.dart';
import 'package:splitify/presentation/screens/scan/scan_qr_screen.dart';
import 'package:splitify/presentation/screens/scan/show_qr_screen.dart';
import 'package:splitify/presentation/screens/friends/friends_list_screen.dart';

class QrOptionsSection extends StatelessWidget {
  final Color primaryColor;

  const QrOptionsSection({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'ATAU',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Tombol untuk Pindai QR
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScanQrScreen()),
            );
          },
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: const Text(
            'Pindai QR Code Teman',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Tombol untuk Tampilkan QR Sendiri
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShowQrScreen()),
            );
          },
          icon: Icon(Icons.qr_code_2_outlined, color: primaryColor),
          label: Text(
            'Tampilkan QR Saya',
            style: TextStyle(fontSize: 16, color: primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        // Divider
        Divider(color: Colors.white.withOpacity(0.2), height: 32),
        const SizedBox(height: 12),
        // Tombol untuk Lihat Daftar Teman
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendsListScreen(),
              ),
            );
          },
          icon: const Icon(Icons.people_outline, color: Colors.white),
          label: const Text(
            'Lihat Daftar Teman',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

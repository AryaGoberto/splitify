show_qr_screen.dart:
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQrScreen extends StatelessWidget {
  const ShowQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    // Ambil UID pengguna saat ini
    final String? userUid = FirebaseAuth.instance.currentUser?.uid;
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userUid == null) {
      return Scaffold(
        backgroundColor: darkBlue,
        appBar: AppBar(
          title: const Text(
            'QR Code Saya',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: darkBlue,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Anda belum login atau UID tidak ditemukan.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'QR Code Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tunjukkan kode ini ke teman Anda untuk ditambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Colors.white, // Background putih untuk kontras dengan QR
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: QrImageView(
                  data: userUid, // Data yang di-encode adalah UID pengguna
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: darkBlue,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: darkBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Identitas Anda:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userEmail ?? 'UID: $userUid',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
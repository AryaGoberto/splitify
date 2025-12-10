// lib/presentation/screens/friends/widgets/friend_result_card.dart

import 'package:flutter/material.dart';

class FriendResultCard extends StatelessWidget {
  final Map<String, dynamic> foundUser;

  const FriendResultCard({super.key, required this.foundUser});

  @override
  Widget build(BuildContext context) {
    const Color inputFieldColor = Color(0xFF1B2A41);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Card(
      color: inputFieldColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: primaryColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          foundUser['name'] ?? 'Nama Pengguna',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          foundUser['email'] ?? 'Email Tidak Ditemukan',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.send, color: Colors.green),
      ),
    );
  }
}

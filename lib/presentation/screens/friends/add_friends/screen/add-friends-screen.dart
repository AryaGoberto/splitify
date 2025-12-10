// lib/presentation/screens/friends/add_friend_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitify/services/user_service.dart';
import '../widget/email_search_form.dart';
import '../widget/friend_result_card.dart';
import '../widget/qr_options_section.dart';


class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _emailController = TextEditingController();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  // State hasil pencarian
  Map<String, dynamic>? _foundUser;
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- Logic Pencarian & Pengiriman Friend Request (Sama seperti sebelumnya) ---
  Future<void> _searchAndAddFriend() async {
    // ... (Logika sama seperti sebelumnya, tidak perlu diubah)
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.toLowerCase().trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (email.isEmpty || currentUid == null) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _foundUser = null;
    });

    try {
      final user = await _userService.findUserByEmail(email);

      if (user != null) {
        if (user['uid'] == currentUid) {
          _message = 'Anda tidak bisa menambahkan diri sendiri.';
          return;
        }

        // Kirim friend request
        await _userService.sendFriendRequest(user['uid']);

        setState(() {
          _foundUser = user;
          _message =
              'Friend request berhasil dikirim ke ${user['name']} (${user['email']})! Tunggu hingga mereka menerima.';
        });
        _emailController.clear();
      } else {
        _message =
            'Pengguna dengan email "$email" tidak ditemukan di Splitify.';
      }
    } catch (e) {
      if (e is FirebaseException) {
        switch (e.code) {
          case 'ALREADY_FRIENDS':
            _message = 'Anda sudah berteman dengan user ini.';
            break;
          case 'REQUEST_EXISTS':
            _message = 'Anda sudah mengirim friend request ke user ini.';
            break;
          default:
            _message = 'Error: ${e.message}';
        }
      } else {
        _message = 'Error saat mencari atau menambahkan: ${e.toString()}';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);
    const Color inputFieldColor = Color(0xFF1B2A41);
    String? formMessage = (_foundUser == null && _message.isNotEmpty)
        ? _message
        : null;

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Tambah Teman',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ganti widget Form dengan EmailSearchForm yang sudah dipecah
            EmailSearchForm(
              formKey: _formKey,
              emailController: _emailController,
              onSearchPressed: _searchAndAddFriend,
              isLoading: _isLoading,
              primaryColor: primaryColor,
              inputFieldColor: inputFieldColor,
              message: formMessage, // Kirim pesan yang relevan ke form
            ),
            const SizedBox(height: 10),

            // Tampilkan Hasil Sukses
            if (_foundUser != null) ...[
              Text(_message, style: const TextStyle(color: Colors.greenAccent)),
              FriendResultCard(foundUser: _foundUser!),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 30),

            // Ganti bagian QR Options dengan QrOptionsSection
            QrOptionsSection(primaryColor: primaryColor),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

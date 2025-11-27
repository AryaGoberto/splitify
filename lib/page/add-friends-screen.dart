import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitify/services/user_service.dart';
// Import layar QR Code yang sudah direncanakan
import 'show_qr_screen.dart';
import './show_qr_screen.dart';

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

  // --- Logic Pencarian & Penambahan Teman ---
  Future<void> _searchAndAddFriend() async {
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

        // Simulasikan penambahan teman
        await _userService.addFriend(user['uid']);

        setState(() {
          _foundUser = user;
          _message =
              '${user['name']} (${user['email']}) berhasil ditambahkan sebagai teman!';
        });
        _emailController.clear();
      } else {
        _message =
            'Pengguna dengan email "$email" tidak ditemukan di Splitify.';
      }
    } catch (e) {
      _message = 'Error saat mencari atau menambahkan: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper Widget untuk menampilkan hasil pencarian
  Widget _buildResultCard() {
    if (_foundUser == null) {
      return Container();
    }

    const Color inputFieldColor = Color(0xFF1B2A41);

    return Card(
      color: inputFieldColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF3B5BFF),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          _foundUser!['name'] ?? 'Nama Pengguna',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _foundUser!['email'] ?? 'Email Tidak Ditemukan',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);
    const Color inputFieldColor = Color(0xFF1B2A41);

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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cari Teman Berdasarkan Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // --- Input Pencarian Email ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@'))
                    return 'Masukkan email yang valid.';
                  return null;
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Masukkan email teman...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: inputFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _searchAndAddFriend,
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Tampilkan Pesan Status
              if (_message.isNotEmpty && _foundUser == null)
                Text(_message, style: const TextStyle(color: Colors.redAccent)),

              // Tampilkan Hasil Sukses
              _buildResultCard(),
              const SizedBox(height: 30),

              // --- Opsi Tambah dengan QR Code ---
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
                    MaterialPageRoute(
                      builder: (context) => const ScanQrScreen(),
                    ),
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
                    MaterialPageRoute(
                      builder: (context) => const ShowQrScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2_outlined, color: primaryColor),
                label: const Text(
                  'Tampilkan QR Saya',
                  style: TextStyle(fontSize: 16, color: primaryColor),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
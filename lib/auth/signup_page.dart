import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitify/page/dashboard_screen.dart';
import './login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../page/scan_struk_page.dart';

class SignUpScreen extends StatefulWidget {
  // Ubah nama kelas menjadi SignUpScreen agar konsisten
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 2. Fungsi Logika Sign Up Firebase
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi Password tidak cocok.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String normalizedEmail = email.toLowerCase();

      // 1️⃣ Buat akun di Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user!;
      await user.updateDisplayName(name);

      // 2️⃣ Buat dokumen user di Firestore: users/<uid>
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email':
            normalizedEmail, // penting: lowercase, cocok dengan UserService.findUserByEmail
        'name': name,
        'friends': <String>[], // array kosong
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ (opsional) bisa juga update photoUrl nanti kalau sudah ada

      // 4️⃣ Navigate ke Dashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuthException during signUp: code=${e.code}, message=${e.message}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pendaftaran Gagal: ${e.code} — ${e.message}')),
      );
    } catch (e, st) {
      debugPrint('Unexpected error during signUp: $e');
      debugPrint(st.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pendaftaran Gagal: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(0.5),
                    darkBlue.withOpacity(0.0),
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),

          // --- 2. Konten Utama (Form Sign Up) ---
          SingleChildScrollView(
            // Mengatasi isu scroll yang tidak perlu saat konten muat
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 80.0,
            ),
            child: Form(
              // Tambahkan Widget Form
              key: _formKey, // Hubungkan Form Key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 50),

                  // Judul Utama
                  const Text(
                    'CREATE\nYOUR ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sub Judul
                  const Text(
                    'Enter your information to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 50),

                  // --- Input Name ---
                  _buildInputField(
                    controller: _nameController,
                    validator: (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // --- Input Email ---
                  _buildInputField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || !value.contains('@'))
                        return 'Format email tidak valid';
                      return null;
                    },
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.length < 6)
                        return 'Password minimal 6 karakter';
                      return null;
                    },
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isObscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Konfirmasi Password wajib diisi';
                      return null;
                    },
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    isObscure: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Tombol Sign Up Utama (Dihubungkan ke _signUp) ---
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _signUp, // Panggil _signUp dan disable saat loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'SIGN UP',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Divider "Or"
                  const Center(
                    child: Text('Or', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 20),

                  // --- Tombol Social Sign Up ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSocialButton('G GOOGLE', 'assets/google.png'),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Link Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Input Field (diperbarui untuk menerima Controller & Validator)
  Widget _buildInputField({
    required String hint,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller, // Diperbarui
    String? Function(String?)? validator, // Diperbarui
  }) {
    return TextFormField(
      controller: controller, // Hubungkan controller
      validator: validator, // Hubungkan validator
      style: const TextStyle(color: Colors.white),
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Widget Pembantu untuk Tombol Sosial
  Widget _buildSocialButton(String text, String imagePath) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

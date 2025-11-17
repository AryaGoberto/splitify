// File: lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import './signup_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF); // Biru Tombol Login

    return Scaffold(
      backgroundColor: darkBlue,
      resizeToAvoidBottomInset: true,
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
                  stops: [0.1, 1.0],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'LOGIN TO\nYOUR ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Enter your login information',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  _buildInputField(
                    hint: 'oliverosa@gmail.com',
                    icon: Icons.email_outlined,
                    isObscure: false,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isObscure: true,
                    suffixIcon: Icons.remove_red_eye_outlined,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (val) {},
                            activeColor: primaryColor,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot password',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('Or', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSocialButton('G GOOGLE', 'assets/google.png'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
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

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    bool isObscure = false,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      obscureText: isObscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05), // Sedikit transparan
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.white54)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

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

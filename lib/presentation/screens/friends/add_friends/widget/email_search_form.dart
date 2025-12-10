// lib/presentation/screens/friends/widgets/email_search_form.dart

import 'package:flutter/material.dart';

class EmailSearchForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final VoidCallback onSearchPressed;
  final bool isLoading;
  final Color primaryColor;
  final Color inputFieldColor;
  final String? message;

  const EmailSearchForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.onSearchPressed,
    required this.isLoading,
    required this.primaryColor,
    required this.inputFieldColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Masukkan email yang valid.';
              }
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
              suffixIcon: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
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
                      onPressed: onSearchPressed,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Tampilkan Pesan Status (jika ada dan bukan hasil sukses)
          if (message != null && message!.isNotEmpty)
            Text(message!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }
}

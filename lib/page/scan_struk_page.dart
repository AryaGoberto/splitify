import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
// Firebase dan MLKit
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScanStrukPage extends StatefulWidget {
  const ScanStrukPage({super.key});

  @override
  State<ScanStrukPage> createState() => _ScanStrukPageState();
}

class _ScanStrukPageState extends State<ScanStrukPage> {
  File? _imageFile;
  late final TextRecognizer _textRecognizer;
  String _recognizedText = "Belum ada teks yang diekstrak.";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // --- Logika Pilih Gambar ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _recognizedText = "Memproses gambar...";
        _isProcessing = true;
      });
      await _processImage();
    }
  }

  // --- Logika Proses Gambar (MLKit) ---
  Future<void> _processImage() async {
    if (_imageFile == null) return;

    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final String extractedText = recognizedText.text.isEmpty
          ? "Tidak ada teks yang ditemukan dalam gambar."
          : recognizedText.text;

      setState(() {
        _recognizedText = extractedText;
      });
    } on MissingPluginException {
      const msg = 'Plugin pengenalan teks tidak tersedia di platform ini.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(msg)));
      }
      setState(() {
        _recognizedText = msg;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memproses gambar: $e')));
      }
      setState(() {
        _recognizedText = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // --- Logika Logout Firebase ---
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate di main.dart akan menangani navigasi otomatis ke LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Splitify: Ekstraksi Teks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Area Display Gambar
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A41),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: _imageFile == null
                  ? const Center(
                      child: Text(
                        'Pilih gambar struk atau tagihan untuk dianalisis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.contain),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Pilih Gambar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 30),

            // Hasil Ekstraksi Teks
            const Text(
              'Teks yang Diekstrak:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A41).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SelectableText(
                _recognizedText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

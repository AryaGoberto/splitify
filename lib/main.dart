import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitify/page/dashboard_screen.dart';
import 'firebase_options.dart';

// Halaman-halaman fitur
import 'auth/signup_page.dart';
import 'auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Debug info: pastikan Firebase berhasil diinisialisasi dan opsi tersedia
  try {
    debugPrint('Firebase apps count: ${Firebase.apps.length}');
    debugPrint(
      'Firebase projectId: ${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
  } catch (e) {
    debugPrint('Error printing Firebase debug info: $e');
  }
  // Set orientasi (Opsional, jika Anda ingin memaksa portrait)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitify App',
      // Mengatur tema dasar aplikasi, menggunakan tema gelap agar konsisten dengan Login/Signup
      theme: ThemeData(
        brightness: Brightness.dark, // Gunakan Dark Theme
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Atur warna fokus input field menjadi biru terang
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B5BFF)),
          ),
        ),
      ),
      // Tentukan halaman utama
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------------------------------
// KODE BARU: Auth Gate (Pemeriksa Status Login)
// -----------------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Memantau perubahan status otentikasi (login/logout)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan loading saat menunggu koneksi Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF000518),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user sudah login (User ada)
        if (snapshot.hasData && snapshot.data != null) {
          // Navigasi ke Halaman Utama (Text Recognition/Home)
          return const DashboardScreen();
        }

        // Jika user belum login (User null)
        // Navigasi ke halaman Login
        return DashboardScreen();
      },
    );
  }
}
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// KODE FITUR: Text Recognition Screen (Halaman Utama Setelah Login)
// -----------------------------------------------------------------------------
class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({super.key});

  @override
  State<TextRecognitionScreen> createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _imageFile;
  late final TextRecognizer _textRecognizer;
  String _recognizedText =
      "No text extracted yet."; // State untuk teks hasil MLKit

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _recognizedText = "Processing image...";
      });
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;
    final inputImage = InputImage.fromFilePath(_imageFile!.path);
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      final String extractedText = recognizedText.text.isEmpty
          ? "No text found in the image."
          : recognizedText.text;

      setState(() {
        _recognizedText = extractedText;
      });
    } on MissingPluginException catch (e) {
      final msg = 'Text recognition plugin is not available on this platform.';
      debugPrint('MissingPluginException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
      setState(() {
        _recognizedText = msg;
      });
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
      setState(() {
        _recognizedText = "Error: $e";
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate akan otomatis menangani navigasi kembali ke LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitify: Text Recognition'),
        backgroundColor: const Color(0xFF0D172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                border: Border.all(color: Colors.white10),
              ),
              child: _imageFile == null
                  ? Center(
                      child: Text(
                        'Tap "Pick Image" to select a bill or receipt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Image.file(_imageFile!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),

            // Tombol Pick Image
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pick Image',
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
              'Extracted Text:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A41).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                // Gunakan SelectableText agar teks bisa dicopy
                _recognizedText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
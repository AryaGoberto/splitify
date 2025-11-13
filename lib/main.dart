import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLKit Text Recognition Demo',
      // Mengatur tema dasar aplikasi, di sini menggunakan tema terang
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false, // Untuk menyembunyikan banner "Debug"
    );
  }
}

class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({super.key});

  @override
  State<TextRecognitionScreen> createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _imageFile;
  late final TextRecognizer _textRecognizer;

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
      final String extractedText = recognizedText.text;
      // You might want to show this in the UI; for now we print to console
      debugPrint(extractedText);
    } on MissingPluginException catch (e) {
      // Plugin not implemented on this platform (e.g., desktop platforms)
      final msg = 'Text recognition plugin is not available on this platform.';
      debugPrint('MissingPluginException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Menampilkan judul yang ada di gambar
        title: const Text(
          'Google MLKit Text Recognition',
          style: TextStyle(
            fontWeight: FontWeight.normal, // Biasanya AppBar tidak bold
          ),
        ),
        // Menghilangkan bayangan di bawah AppBar
        elevation: 0,
        backgroundColor: Colors.white, // Latar belakang putih
        foregroundColor: Colors.black, // Warna teks hitam
      ),
      // Konten utama diletakkan di tengah layar
      body: Center(
        child: Column(
          // Memastikan konten di tengah secara vertikal
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Teks instruksi
            const Text(
              'Select an image to analyze.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54, // Warna abu-abu untuk teks instruksi
              ),
            ),
            // Memberi sedikit jarak vertikal
            const SizedBox(height: 20),
            // Tombol "Pick Image"
            ElevatedButton(
              onPressed: _pickImage, // Memanggil fungsi placeholder
              style: ElevatedButton.styleFrom(
                // Warna latar belakang tombol (mirip ungu muda/lavender)
                backgroundColor: const Color(
                  0xFFE8EAF6,
                ), // Warna dari palet Material Design
                foregroundColor: Colors.black, // Warna teks tombol
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0, // Menghilangkan bayangan tombol
              ),
              child: const Text(
                'Pick Image',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

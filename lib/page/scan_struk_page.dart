import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
// Firebase dan MLKit
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';


class ScanStrukPage extends StatefulWidget {
  const ScanStrukPage({super.key});

  @override
  State<ScanStrukPage> createState() => _ScanStrukPageState();
}

class _ScanStrukPageState extends State<ScanStrukPage> {
  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;

  File? _capturedImage;
  String _recognizedText = "";
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _showConfirmation = false;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initializeCamera();
  }

  // Inisialisasi kamera
  Future<void> _initializeCamera() async {
      var status = await Permission.camera.request();
  if (!status.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akses kamera ditolak')),
    );
    return;
  }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada kamera tersedia')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inisialisasi kamera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // Ambil foto dari kamera
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile picture = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(picture.path);
        _showConfirmation = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil foto: $e')),
        );
      }
    }
  }

  // Import gambar dari galeri
  Future<void> _importImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
        _showConfirmation = true;
      });
    }
  }

  // Konfirmasi gambar (ceklist)
  Future<void> _confirmImage() async {
    setState(() {
      _showConfirmation = false;
      _isProcessing = true;
    });
    await _processImage();
  }

  // Batalkan gambar (ambil ulang)
  void _cancelImage() {
    setState(() {
      _capturedImage = null;
      _showConfirmation = false;
      _recognizedText = "";
    });
  }

  // Proses OCR
  Future<void> _processImage() async {
    if (_capturedImage == null) return;

    try {
      final inputImage = InputImage.fromFilePath(_capturedImage!.path);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(msg)),
        );
      }
      setState(() {
        _recognizedText = msg;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memproses gambar: $e')),
        );
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

  // Logout Firebase
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    // Jika sedang menampilkan konfirmasi gambar
    if (_showConfirmation) {
      return _buildConfirmationScreen(darkBlue, primaryColor);
    }

    // Jika sudah ada hasil OCR
    if (_recognizedText.isNotEmpty && !_isProcessing) {
      return _buildResultScreen(darkBlue, primaryColor);
    }

    // Tampilan kamera utama
    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar dengan tombol import
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      onPressed: _importImage,
                      tooltip: 'Import dari Galeri',
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Capture di tengah bawah
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: primaryColor,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Color(0xFF0D172A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Screen konfirmasi gambar
  Widget _buildConfirmationScreen(Color darkBlue, Color primaryColor) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text('Konfirmasi Gambar', style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _cancelImage,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _capturedImage != null
                  ? Image.file(_capturedImage!, fit: BoxFit.contain)
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelImage,
                    icon: const Icon(Icons.close),
                    label: const Text('Batal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmImage,
                    icon: const Icon(Icons.check),
                    label: const Text('Proses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Screen hasil OCR
  Widget _buildResultScreen(Color darkBlue, Color primaryColor) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text('Hasil Ekstraksi', style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _capturedImage = null;
              _recognizedText = "";
              _showConfirmation = false;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview gambar
            if (_capturedImage != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A41),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_capturedImage!, fit: BoxFit.contain),
                ),
              ),
            const SizedBox(height: 20),

            // Hasil teks
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
              child: _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SelectableText(
                      _recognizedText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Tombol scan lagi
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _capturedImage = null;
                  _recognizedText = "";
                  _showConfirmation = false;
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

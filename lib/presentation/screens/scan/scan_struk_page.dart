import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:splitify/services/gemini_ocr_service.dart';
import 'package:splitify/services/receipt_service.dart';
import 'package:splitify/services/notification_service.dart';
import 'package:splitify/config/app_config.dart' as config;

class ScanStrukPage extends StatefulWidget {
  const ScanStrukPage({super.key});

  @override
  State<ScanStrukPage> createState() => _ScanStrukPageState();
}

class _ScanStrukPageState extends State<ScanStrukPage> {
  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;
  late final GeminiOCRService _geminiOCR;
  late final ReceiptService _receiptService;

  File? _capturedImage;
  String _recognizedText = "";
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _showConfirmation = false;
  Map<String, dynamic> _extractedData = {};

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    // Initialize Gemini dengan API key (pastikan set di environment/firebase config)
    _geminiOCR = GeminiOCRService(apiKey: _getApiKey());
    _receiptService = ReceiptService();
    _initializeCamera();
  }

  String _getApiKey() {
    // Get dari AppConfig yang bisa read dari environment/Firebase
    final key = config.AppConfig.geminiApiKey;
    print('🔑 Gemini API Key Status:');
    print('   - Is Configured: ${config.AppConfig.isConfigured}');
    print('   - Key Length: ${key.length}');
    print(
      '   - Key: ${key.isEmpty ? "[EMPTY - Using Fallback]" : "[SET - ${key.substring(0, 10)}...]"}',
    );

    return key.isEmpty
        ? 'AIzaSyDvLFu8xdbKNJbwIH9rPq87mhgCZGYj_Bk' // Fallback temporary
        : key;
  }

  // Inisialisasi kamera
  Future<void> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akses kamera ditolak')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error mengambil foto: $e')));
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

  // Proses OCR dengan Gemini
  Future<void> _processImage() async {
    if (_capturedImage == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      Map<String, dynamic> data;

      // --- Panggilan Gemini OCR ---

      try {
        print('🚀 Attempting Gemini OCR...');
        print('📁 Image path: ${_capturedImage!.path}');
        print('📏 Image size: ${await _capturedImage!.length()} bytes');

        // Memanggil GeminiOCRService.extractReceiptData yang dijamin mengembalikan Map valid
        data = await _geminiOCR.extractReceiptData(_capturedImage!);

        print('✅ Gemini returned data: $data');
      } catch (geminiError) {
        // Catch jika terjadi masalah koneksi, API key, atau error di luar parsing
        print('❌ Gemini OCR failed: $geminiError');
        print('🔍 Error type: ${geminiError.runtimeType}');
        print('⚠️ Falling back to MLKit text recognition...');

        // Langsung fallback ke MLKit - extract raw text saja
        await _processImageWithMLKit();
        return;
      }

      // --- Cek Validitas Data Hasil Gemini ---

      final items = data['items'] as List? ?? [];
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;

      print(
        '📋 Extracted: ${items.length} items, Total: $total, Subtotal: $subtotal',
      );

      // Jika items kosong tapi ada total/subtotal, buat generic item
      if (items.isEmpty && (total > 0 || subtotal > 0)) {
        print('⚠️ Items kosong tapi ada total. Creating generic item...');

        final genericPrice = total > 0 ? total : subtotal;
        data['items'] = [
          {'name': 'Pesanan', 'price': genericPrice, 'quantity': 1},
        ];

        // Pastikan total konsisten
        if (data['subtotal'] == 0) {
          data['subtotal'] = genericPrice;
        }
        if (data['total'] == 0) {
          data['total'] = genericPrice;
        }
      }

      // Fallback jika BENAR2 kosong (no items AND no total)
      if (items.isEmpty && total == 0 && subtotal == 0) {
        print('⚠️ Truly empty data. Falling back to MLKit...');
        await _processImageWithMLKit();
        return;
      }

      // --- Simpan ke Firestore dulu ---
      print('💾 Saving to Firestore...');
      String receiptId;
      try {
        receiptId = await _receiptService.saveReceipt(
          receiptData: data,
          imagePath: _capturedImage!.path,
        );
        print('✅ Saved to Firestore with ID: $receiptId');
      } catch (firestoreError) {
        print('❌ Failed to save to Firestore: $firestoreError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan ke database: $firestoreError'),
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // --- Load dari Firestore untuk ditampilkan ---
      print('📥 Loading from Firestore...');
      final savedData = await _receiptService.getReceipt(receiptId);
      if (savedData == null) {
        print('❌ Failed to load from Firestore');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // --- Success State (dari Firestore) ---

      print('📊 Loaded Data from Firestore:');

      print('   - Items: ${(savedData['items'] as List).length}');

      print('   - Total: ${savedData['total']}');

      setState(() {
        _extractedData = savedData;

        _recognizedText = _formatReceiptData(savedData);

        _isProcessing = false;
      });

      if (mounted) {
        final itemCount = (savedData['items'] as List).length;

        // Show notification
        await NotificationService().showReceiptOCRCompleteNotification(
          itemCount,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Receipt OCR Complete! $itemCount items found. Ready to review.',
            ),

            backgroundColor: const Color(0xFF3B5BFF),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Catch-all untuk error yang tidak tertangani

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memproses gambar: $e')));
      }

      setState(() {
        _recognizedText = "Fatal Error: $e";

        _isProcessing = false;
      });
    }
  }

  Future<void> _processImageWithMLKit() async {
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
        // Set minimal extracted data agar bisa di-pass ke parent
        _extractedData = {
          'items': [],
          'subtotal': 0,
          'tax': 0,
          'service_charge': 0,
          'discount': 0,
          'total': 0,
          'restaurant_name': '',
          'date': '',
          'recognized_text': extractedText, // Add raw text untuk reference
        };
        _isProcessing = false;
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
        // Set minimal extracted data even on error
        _extractedData = {
          'items': [],
          'subtotal': 0,
          'tax': 0,
          'service_charge': 0,
          'discount': 0,
          'total': 0,
          'restaurant_name': '',
          'date': '',
          'recognized_text': msg,
        };
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error MLKit: $e')));
      }
      setState(() {
        _recognizedText = "MLKit Error: $e";
        // Set minimal extracted data even on error
        _extractedData = {
          'items': [],
          'subtotal': 0,
          'tax': 0,
          'service_charge': 0,
          'discount': 0,
          'total': 0,
          'restaurant_name': '',
          'date': '',
          'recognized_text': "MLKit Error: $e",
        };
        _isProcessing = false;
      });
    }
  }

  String _formatReceiptData(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln('📋 ITEM PESANAN:');
      for (final item in items) {
        final name = item['name'] ?? 'Unknown';
        final price = item['price'] ?? 0;
        final qty = item['quantity'] ?? 1;
        buffer.writeln('  • $name x$qty = Rp $price');
      }
      buffer.writeln();
    }

    final restaurantName = data['restaurant_name'] ?? '';
    if (restaurantName.isNotEmpty) {
      buffer.writeln('🏪 Tempat: $restaurantName');
    }

    final date = data['date'] ?? '';
    if (date.isNotEmpty) {
      buffer.writeln('📅 Tanggal: $date');
    }

    buffer.writeln();
    buffer.writeln('💰 RINGKASAN:');
    buffer.writeln('  Subtotal: Rp ${data['subtotal'] ?? 0}');
    if ((data['tax'] as num? ?? 0) > 0) {
      buffer.writeln('  Pajak: Rp ${data['tax'] ?? 0}');
    }
    if ((data['service_charge'] as num? ?? 0) > 0) {
      buffer.writeln('  Service: Rp ${data['service_charge'] ?? 0}');
    }
    if ((data['discount'] as num? ?? 0) > 0) {
      buffer.writeln('  Diskon: -Rp ${data['discount'] ?? 0}');
    }
    buffer.writeln('  TOTAL: Rp ${data['total'] ?? 0}');

    return buffer.toString();
  }

  // Logout Firebase
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  bool _hasValidExtractedData() {
    if (_extractedData.isEmpty) return false;

    final items = _extractedData['items'] as List?;
    // Kita menggunakan double di _normalizeData, jadi cek sebagai num
    final total = _extractedData['total'] as num?;

    // Data dianggap valid jika ada item ATAU total lebih besar dari nol.
    return (items?.isNotEmpty == true) || (total ?? 0) > 0;
  }

  // Build widget untuk menampilkan data ekstraksi yang sudah diparse
  Widget _buildExtractedDataDisplay(Color primaryColor) {
    final items = _extractedData['items'] as List<dynamic>? ?? [];
    final subtotal = (_extractedData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final tax = (_extractedData['tax'] as num?)?.toDouble() ?? 0.0;
    final service =
        (_extractedData['service_charge'] as num?)?.toDouble() ?? 0.0;
    final discount = (_extractedData['discount'] as num?)?.toDouble() ?? 0.0;
    final total = (_extractedData['total'] as num?)?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A41),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items
          if (items.isNotEmpty) ...[
            const Text(
              '📋 PESANAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final item = entry.value as Map<String, dynamic>;
              final name = item['name'] ?? 'Item';
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$name x$qty',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      'Rp ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(color: Colors.white10, height: 16),
          ],

          // Summary
          const Text(
            '💰 RINGKASAN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Rp ${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tax
          if (tax > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pajak',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Rp ${tax.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Service
          if (service > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Rp ${service.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Discount
          if (discount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diskon',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '-Rp ${discount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(color: Colors.white10, height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              Positioned.fill(child: CameraPreview(_cameraController!))
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
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
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
                      border: Border.all(color: primaryColor, width: 4),
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

            // Loading overlay saat processing
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF3B5BFF)),
                      const SizedBox(height: 24),
                      const Text(
                        'Processing Receipt...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Extracting items with AI',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
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
        title: const Text(
          'Konfirmasi Gambar',
          style: TextStyle(color: Colors.white),
        ),
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
        title: const Text(
          'Hasil Ekstraksi',
          style: TextStyle(color: Colors.white),
        ),
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
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
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
                  if (_hasValidExtractedData())
                    _buildExtractedDataDisplay(primaryColor)
                  else if (_extractedData.isNotEmpty)
                    Column(
                      children: [
                        _buildExtractedDataDisplay(primaryColor),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Items tidak terdeteksi. Silakan edit manual atau scan ulang.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2A41).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SelectableText(
                        _recognizedText.isEmpty
                            ? 'Sedang memproses...'
                            : _recognizedText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Tombol gunakan data extracted
                  if (_extractedData.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Kirim data ke create activity screen
                        Navigator.of(context).pop(_extractedData);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Gunakan Data Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Tombol scan lagi
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                        _recognizedText = "";
                        _showConfirmation = false;
                        _extractedData = {};
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

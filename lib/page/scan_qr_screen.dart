import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:splitify/services/user_service.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  // Controller untuk mengontrol kamera
  MobileScannerController cameraController = MobileScannerController();
  final UserService _userService = UserService();

  // Flag untuk mencegah pemrosesan scan ganda
  bool _isProcessingScan = false;

  // Local state for torch and camera facing
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(Barcode barcode) async {
    if (_isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
    });

    final String? scannedUid = barcode.rawValue;

    if (scannedUid != null && scannedUid.isNotEmpty) {
      cameraController.stop();

      String message = '';
      try {
        if (scannedUid.length < 10) {
          message = 'Gagal: Kode yang dipindai bukan UID Firebase yang valid.';
          throw Exception('Invalid UID length');
        }

        await _userService.addFriend(scannedUid);
        message = 'Berhasil! Teman berhasil ditambahkan.';
      } catch (e) {
        // Menangani error dari UserService (misalnya, mencoba menambah diri sendiri)
        message = 'Gagal menambahkan teman: ${e.toString()}';
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Status Penambahan Teman'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  cameraController.start();
                  setState(() {
                    _isProcessingScan = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR Code tidak valid.')));
      }
      cameraController.start();
      setState(() {
        _isProcessingScan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Pindai QR Teman',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        actions: [
          // Tombol Flash/Torch
          IconButton(
            color: Colors.white,
            icon: _torchEnabled
                ? const Icon(Icons.flash_on, color: Colors.yellow)
                : const Icon(Icons.flash_off, color: Colors.grey),
            iconSize: 32.0,
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
            },
          ),

          // Tombol Switch Camera
          IconButton(
            color: Colors.white,
            icon: _cameraFacing == CameraFacing.front
                ? const Icon(Icons.camera_front)
                : _cameraFacing == CameraFacing.back
                ? const Icon(Icons.camera_rear)
                : const Icon(Icons.camera_alt), // for external
            iconSize: 32.0,
            onPressed: () async {
              await cameraController.switchCamera();
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Area pemindai kamera
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                _onDetect(capture.barcodes.first);
              }
            },
          ),
          // Overlay untuk membantu pengguna fokus pada QR
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Posisikan QR Code teman di dalam kotak untuk memindai.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
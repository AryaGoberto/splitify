import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../widget/choose_method_card.dart';
import 'scan_struk_screen.dart';
import 'manual_input_screen.dart';
import '../../scan_struk_page.dart';

class ChooseMethodScreen extends StatefulWidget {
  final String activityName;
  final DateTime activityDate;
  final List<String> members;
  final List<String> memberUids;

  const ChooseMethodScreen({
    super.key,
    required this.activityName,
    required this.activityDate,
    required this.members,
    required this.memberUids,
  });

  @override
  State<ChooseMethodScreen> createState() => _ChooseMethodScreenState();
}

class _ChooseMethodScreenState extends State<ChooseMethodScreen> {
  void _scanReceipt() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanStrukPage()),
    );

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanStruk(
            activityName: widget.activityName,
            activityDate: widget.activityDate,
            members: widget.members,
            memberUids: widget.memberUids,
            scannedData: result,
          ),
        ),
      );
    }
  }

  void _inputManual() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualInputScreen(
          activityName: widget.activityName,
          activityDate: widget.activityDate,
          members: widget.members,
          memberUids: widget.memberUids,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Choose Method',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: 0.66,
              backgroundColor: white10,
              color: primaryColor,
            ),
            const SizedBox(height: 30),

            // Title & Subtitle
            const Text(
              'Bagaimana cara input pesanan?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pilih salah satu metode untuk melanjutkan',
              style: TextStyle(color: white70, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Scan Struk Card
            ChooseMethodCard(
              onTap: _scanReceipt,
              icon: Icons.receipt_long,
              iconColor: primaryColor,
              splashColor: primaryColor.withOpacity(0.2),
              title: 'Scan Struk',
              description:
                  'Foto/scan nota untuk deteksi otomatis item dan harga',
              hint: 'Lebih cepat & akurat',
              hintColor: primaryColor,
              borderColor: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),

            // Input Manual Card
            ChooseMethodCard(
              onTap: _inputManual,
              icon: Icons.edit_note,
              iconColor: white70,
              splashColor: white10,
              title: 'Input Manual',
              description:
                  'Masukkan item dan harga satu per satu secara manual',
              hint: 'Untuk pesanan kecil atau tidak ada nota',
              hintColor: white60,
              borderColor: white24,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

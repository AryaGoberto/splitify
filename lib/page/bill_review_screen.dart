import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_item.dart';

class BillReviewScreen extends StatefulWidget {
  final String activityName;
  final DateTime activityDate;
  final List<String> members;
  final List<BillItem> items;
  final double taxPercent;
  final double servicePercent;
  final double discountNominal;
  final Map<String, double> memberTotals;

  const BillReviewScreen({
    super.key,
    required this.activityName,
    required this.activityDate,
    required this.members,
    required this.items,
    required this.taxPercent,
    required this.servicePercent,
    required this.discountNominal,
    required this.memberTotals,
  });

  @override
  State<BillReviewScreen> createState() => _BillReviewScreenState();
}

class _BillReviewScreenState extends State<BillReviewScreen> {
  late Map<String, double> _memberTotals;

  @override
  void initState() {
    super.initState();
    _memberTotals = widget.memberTotals;
  }

  double get _subtotal => widget.items.fold<double>(0, (s, i) => s + i.price);

  double get _tax => _subtotal * (widget.taxPercent / 100);

  double get _service => _subtotal * (widget.servicePercent / 100);

  double get _grandTotal =>
      _subtotal + _tax + _service - widget.discountNominal;

  void _submitActivity() {
    // TODO: Save ke Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aktivitas disimpan! (Firestore integration coming soon)',
        ),
        backgroundColor: Color(0xFF3B5BFF),
      ),
    );

    // Pop kembali ke home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Ringkasan Pembayaran',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMMM yyyy').format(widget.activityDate),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, color: primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.members.length} anggota',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Items List
            const Text(
              'Detail Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Pemesan: ${item.member}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Summary
            const Text(
              'Ringkasan Biaya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Subtotal', _subtotal),
                  if (widget.taxPercent > 0)
                    _buildSummaryRow('Pajak (${widget.taxPercent}%)', _tax),
                  if (widget.servicePercent > 0)
                    _buildSummaryRow(
                      'Service (${widget.servicePercent}%)',
                      _service,
                    ),
                  if (widget.discountNominal > 0)
                    _buildSummaryRow('Diskon', -widget.discountNominal),
                  const Divider(color: Colors.white12, height: 16),
                  _buildSummaryRow('Total Bayar', _grandTotal, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Per-Member Breakdown
            const Text(
              'Pembayaran Per Orang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: _memberTotals.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withOpacity(0.2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      e.key[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  e.key,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${e.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Anggota List
            const Text(
              'Daftar Anggota',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.members
                  .map(
                    (member) => Chip(
                      backgroundColor: primaryColor.withOpacity(0.2),
                      label: Text(
                        member,
                        style: const TextStyle(color: Colors.white),
                      ),
                      avatar: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          member[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      // Bottom Action Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: ElevatedButton.icon(
            onPressed: _submitActivity,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text(
              'Simpan Aktivitas',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 15 : 14,
            ),
          ),
          Text(
            'Rp ${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBold ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

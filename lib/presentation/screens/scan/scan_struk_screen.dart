import 'package:flutter/material.dart';
import '../../../data/models/bill_item.dart';
import '../../../services/activity_service.dart';

class ScanStruk extends StatefulWidget {
  final String activityName;
  final DateTime activityDate;
  final List<String> members;
  final List<String> memberUids;
  final Map<String, dynamic> scannedData;

  const ScanStruk({
    super.key,
    required this.activityName,
    required this.activityDate,
    required this.members,
    required this.memberUids,
    required this.scannedData,
  });

  @override
  State<ScanStruk> createState() => _ScanStrukState();
}

class _ScanStrukState extends State<ScanStruk> {
  final ActivityService _activityService = ActivityService();
  final TextEditingController _taxValueController = TextEditingController();
  final TextEditingController _serviceValueController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  late List<BillItem> _items;
  late double _taxPercent;
  late double _taxNominal;
  late double _servicePercent;
  late double _serviceNominal;
  late double _discountNominal;
  bool _isSaving = false;
  bool _taxIsPersen = true;
  bool _serviceIsPersen = true;

  @override
  void initState() {
    super.initState();
    _processScannedData();
  }

  @override
  void dispose() {
    _taxValueController.dispose();
    _serviceValueController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _processScannedData() {
    final items = widget.scannedData['items'] ?? [];

    // Set pajak dan service ke 0 di awal (user bisa edit manual)
    _taxPercent = 0.0;
    _taxNominal = 0.0;
    _servicePercent = 0.0;
    _serviceNominal = 0.0;

    final discountValue = widget.scannedData['discount'];
    _discountNominal = (discountValue is num ? discountValue.toDouble() : 0.0);

    _items = [];
    for (var item in items) {
      final priceValue = item['price'];
      _items.add(
        BillItem(
          member: widget.members.isNotEmpty ? widget.members.first : '',
          name: item['name'] ?? 'Item',
          price: (priceValue is num ? priceValue.toDouble() : 0.0),
        ),
      );
    }
  }

  void _updateItemAssignment(int index, String member) {
    setState(() {
      _items[index] = BillItem(
        member: member,
        name: _items[index].name,
        price: _items[index].price,
      );
    });
  }

  Future<void> _saveActivity() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Hitung pajak dan service berdasarkan tipe (persen atau nominal)
      double finalTaxPercent = _taxIsPersen ? _taxPercent : 0;
      double finalServicePercent = _serviceIsPersen ? _servicePercent : 0;
      double finalDiscount = _discountNominal;

      // Jika nominal, convert ke persen berdasarkan subtotal
      final subtotal = _items.fold<double>(0, (s, i) => s + i.price);
      if (!_taxIsPersen && _taxNominal > 0) {
        finalTaxPercent = ((_taxNominal / subtotal) * 100);
      }
      if (!_serviceIsPersen && _serviceNominal > 0) {
        finalServicePercent = ((_serviceNominal / subtotal) * 100);
      }

      await _activityService.createActivity(
        activityName: widget.activityName,
        activityDate: widget.activityDate,
        members: widget.members,
        memberUids: widget.memberUids,
        items: _items,
        taxPercent: finalTaxPercent,
        servicePercent: finalServicePercent,
        discountNominal: finalDiscount,
        inputMethod: 'scan',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to activity creation screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double get _subtotal => _items.fold<double>(0, (s, i) => s + i.price);

  double get _tax {
    if (_taxIsPersen) {
      return _subtotal * (_taxPercent / 100);
    } else {
      return _taxNominal;
    }
  }

  double get _service {
    if (_serviceIsPersen) {
      return _subtotal * (_servicePercent / 100);
    } else {
      return _serviceNominal;
    }
  }

  double get _grandTotal => _subtotal + _tax + _service - _discountNominal;

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Review Hasil Scan (3/3)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.white10,
                  color: primaryColor,
                ),
                const SizedBox(height: 20),

                // Items List
                const Text(
                  'Pesanan yang Terdeteksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Tidak ada item terdeteksi',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        color: const Color(0xFF1B2A41),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: item.member,
                                dropdownColor: const Color(0xFF0D172A),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Dipesan oleh',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0D172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: widget.members
                                    .map(
                                      (member) => DropdownMenuItem(
                                        value: member,
                                        child: Text(member),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _updateItemAssignment(index, value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Pajak & Service Edit Section
                const Text(
                  'Pajak & Layanan (Opsional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // PAjak
                const Text(
                  'Pajak',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Persen (%)'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Nominal (Rp)'),
                          ),
                        ],
                        selected: <bool>{_taxIsPersen},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _taxIsPersen = newSelection.first;
                            _taxValueController.clear();
                            _taxPercent = 0;
                            _taxNominal = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _taxValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _taxIsPersen ? 'Pajak (%)' : 'Pajak (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() {
                    if (_taxIsPersen) {
                      _taxPercent = double.tryParse(val) ?? 0;
                      _taxNominal = 0;
                    } else {
                      _taxNominal = double.tryParse(val) ?? 0;
                      _taxPercent = 0;
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // Service
                const Text(
                  'Service',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Persen (%)'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Nominal (Rp)'),
                          ),
                        ],
                        selected: <bool>{_serviceIsPersen},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _serviceIsPersen = newSelection.first;
                            _serviceValueController.clear();
                            _servicePercent = 0;
                            _serviceNominal = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _serviceIsPersen
                        ? 'Service (%)'
                        : 'Service (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() {
                    if (_serviceIsPersen) {
                      _servicePercent = double.tryParse(val) ?? 0;
                      _serviceNominal = 0;
                    } else {
                      _serviceNominal = double.tryParse(val) ?? 0;
                      _servicePercent = 0;
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // Diskon
                const Text(
                  'Diskon',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Diskon (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(
                    () => _discountNominal = double.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(height: 24),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A41),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Subtotal', _subtotal),
                      _buildSummaryRow('Pajak', _tax),
                      _buildSummaryRow('Service', _service),
                      if (_discountNominal > 0)
                        _buildSummaryRow('Diskon', -_discountNominal),
                      const Divider(color: Colors.white30),
                      _buildSummaryRow('TOTAL', _grandTotal, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Save Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: darkBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveActivity,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Aktivitas',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            'Rp ${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

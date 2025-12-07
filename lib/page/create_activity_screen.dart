import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'bill_review_screen.dart';
// Import widgets dari folder 'widget'
import '../widget/member_section.dart';
import '../widget/item_input_section.dart';
import '../widget/bill_summary_section.dart';
import '../models/bill_item.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  // State
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedMembers = ['Arya', 'Bryan', 'Nawwaf'];
  String? _selectedPayer;
  final List<BillItem> _items = [];
  double _taxPercent = 0;
  double _servicePercent = 0;
  double _discountNominal = 0;

  // --- LOGIC (Perhitungan dan Manipulasi State, tetap di sini) ---

  Map<String, double> get _memberTotals {
    final totals = <String, double>{};
    if (_items.isEmpty) return totals;
    final subtotal = _items.fold<double>(0, (s, i) => s + i.price);
    if (subtotal == 0) return totals;

    final tax = _subtotal * (_taxPercent / 100);
    final service = _subtotal * (_servicePercent / 100);
    final discount = _discountNominal;

    final memberSub = <String, double>{};
    for (final it in _items) {
      memberSub[it.member] = (memberSub[it.member] ?? 0) + it.price;
    }

    memberSub.forEach((member, sub) {
      final prop = sub / subtotal;
      final memberTax = tax * prop;
      final memberService = service * prop;
      final memberDiscount = discount * prop;
      totals[member] = sub + memberTax + memberService - memberDiscount;
    });

    return totals;
  }

  double get _subtotal => _items.fold<double>(0, (s, i) => s + i.price);
  double get _tax => _subtotal * (_taxPercent / 100);
  double get _service => _subtotal * (_servicePercent / 100);
  double get _grandTotal => _subtotal + _tax + _service - _discountNominal;

  @override
  void dispose() {
    _activityNameController.dispose();
    _memberSearchController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  // Helper untuk input standar (DIPERTAHANKAN)
  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color primaryColor = Color(0xFF3B5BFF);
    const Color inputFieldColor = Color(0xFF0D172A);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: inputFieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wajib diisi.';
        }
        return null;
      },
    );
  }

  // Helper untuk label di atas input (DIPERTAHANKAN)
  Widget _buildLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // --- LOGIC DETAIL (selectDate, addMember, removeMember, continueActivity, addItem, scanReceipt, processScannedReceipt) ---
  // Semua method ini harus dipindahkan ke sini karena mereka memanggil setState.

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      // Styling
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B5BFF),
              onPrimary: Colors.white,
              surface: Color(0xFF1B2A41),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D172A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addMember() {
    final newMember = _memberSearchController.text.trim();
    if (newMember.isNotEmpty && !_selectedMembers.contains(newMember)) {
      setState(() {
        _selectedMembers.add(newMember);
        _memberSearchController.clear();
      });
    } else if (_selectedMembers.contains(newMember)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$newMember sudah ada di daftar anggota.')),
      );
    }
  }

  void _removeMember(String member) {
    setState(() {
      _selectedMembers.remove(member);
    });
  }

  void _continueActivity() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal 1 anggota.')),
        );
        return;
      }

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambah minimal 1 item pesanan.')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BillReviewScreen(
            activityName: _activityNameController.text.trim(),
            activityDate: _selectedDate,
            members: _selectedMembers,
            items: _items
                .map(
                  (item) => BillItem(
                    member: item.member,
                    name: item.name,
                    price: item.price,
                  ),
                )
                .toList(),
            taxPercent: _taxPercent,
            servicePercent: _servicePercent,
            discountNominal: _discountNominal,
            memberTotals: _memberTotals,
          ),
        ),
      );
    }
  }

  void _addItem() {
    if ((_selectedPayer ?? '').isEmpty) {
      _selectedPayer = _selectedMembers.isNotEmpty
          ? _selectedMembers.first
          : null;
    }
    final name = _itemNameController.text.trim();
    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0;
    final payer = _selectedPayer;
    if (name.isEmpty || price <= 0 || payer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama item, harga > 0, dan pilih pemesan.'),
        ),
      );
      return;
    }
    setState(() {
      _items.add(BillItem(member: payer, name: name, price: price));
      _itemNameController.clear();
      _itemPriceController.clear();
    });
  }

  Future<void> _scanReceipt() async {
    final result = await Navigator.of(context).pushNamed('/scan-struk');
    if (result != null && result is Map<String, dynamic>) {
      _processScannedReceipt(result);
    }
  }

  void _processScannedReceipt(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final tax = (data['tax'] as num?)?.toDouble() ?? 0;
    final service = (data['service_charge'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;

    setState(() {
      // Add items
      for (final item in items) {
        final name = item['name'] as String? ?? '';
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;

        if (name.isNotEmpty && price > 0) {
          final payer =
              _selectedPayer ??
              (_selectedMembers.isNotEmpty ? _selectedMembers.first : null);
          if (payer != null) {
            _items.add(
              BillItem(member: payer, name: '$name x$qty', price: price * qty),
            );
          }
        }
      }

      // Update charges
      final currentSubtotal = _items.fold<double>(0, (s, i) => s + i.price);
      _taxPercent = tax > 0
          ? ((tax / (currentSubtotal - tax - service + discount)) * 100).clamp(
              0,
              100,
            )
          : 0;
      _servicePercent = service > 0
          ? ((service / (currentSubtotal - tax - service + discount)) * 100)
                .clamp(0, 100)
          : 0;
      _discountNominal = discount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} item berhasil ditambahkan dari struk'),
        backgroundColor: const Color(0xFF3B5BFF),
      ),
    );
  }

  // --- METHOD BUILD UTAMA (Menggunakan Widget Eksternal) ---

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);
    final String formattedDate = DateFormat(
      'dd MMMM yyyy',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Buat Aktivitas Baru',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. NAMA AKTIVITAS
                  const Text(
                    'Nama Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInputField(
                    hint: 'Contoh: Makan Malam Angkatan',
                    controller: _activityNameController,
                  ),
                  const SizedBox(height: 25),

                  // 2. TANGGAL AKTIVITAS
                  const Text(
                    'Tanggal Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.35)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: primaryColor,
                      ),
                      title: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text(
                          'Ubah',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. ANGGOTA AKTIVITAS (Menggunakan Widget Eksternal)
                  MemberSection(
                    controller: _memberSearchController,
                    selectedMembers: _selectedMembers,
                    onAddMember: _addMember,
                    onRemoveMember: _removeMember,
                  ),
                  const SizedBox(height: 10),
                  // Status Anggota Minimal
                  Text(
                    '* minimal 1 anggota untuk lanjut',
                    style: TextStyle(
                      color: _selectedMembers.isEmpty
                          ? Colors.redAccent
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 4. TAMBAH PESANAN (Menggunakan Widget Eksternal)
                  ItemInputSection(
                    members: _selectedMembers,
                    selectedPayer: _selectedPayer,
                    nameController: _itemNameController,
                    priceController: _itemPriceController,
                    items: _items,
                    onPayerChanged: (val) =>
                        setState(() => _selectedPayer = val),
                    onAddItem: _addItem,
                    onScanReceipt: _scanReceipt,
                    onRemoveItem: (index) =>
                        setState(() => _items.removeAt(index)),
                  ),
                  const SizedBox(height: 25),

                  // 5. PAJAK & LAYANAN (Dipotong untuk hanya menyisakan bagian Charges)
                  const Text(
                    'Pajak & Layanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeled(
                          'Pajak (%)',
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: const Color(0xFF0D172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) => setState(
                              () => _taxPercent = double.tryParse(val) ?? 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeled(
                          'Service (%)',
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: const Color(0xFF0D172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) => setState(
                              () => _servicePercent = double.tryParse(val) ?? 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLabeled(
                    'Diskon (nominal)',
                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0',
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
                  ),

                  const SizedBox(height: 20),

                  // 6. RINGKASAN (Menggunakan Widget Eksternal)
                  BillSummarySection(
                    subtotal: _subtotal,
                    tax: _tax,
                    service: _service,
                    discount: _discountNominal,
                    grandTotal: _grandTotal,
                    memberTotals: _memberTotals,
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // 7. Tombol Lanjut (Fixed Bottom)
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
                  onPressed: _continueActivity,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Lanjut',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
}

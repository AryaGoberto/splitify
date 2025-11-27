import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Digunakan untuk memformat tanggal (Pastikan paket intl sudah diinstal!)

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  
  // State untuk tanggal dan anggota
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedMembers = ['Arya', 'Bryan', 'Nawwaf']; // Dummy members

  @override
  void dispose() {
    _activityNameController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      // Styling untuk Date Picker
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B5BFF), // primaryColor
              onPrimary: Colors.white,
              surface: Color(0xFF1B2A41), // inputFieldColor
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D172A), // darkBlue
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

  // --- Logic Tambah Anggota (Dummy) ---
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

  // --- Logic Hapus Anggota ---
  void _removeMember(String member) {
    setState(() {
      _selectedMembers.remove(member);
    });
  }
  
  // --- Logic Lanjut (Simpan Aktivitas) ---
  void _continueActivity() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.length < 1) { // Asumsi minimal 1 anggota selain diri sendiri
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal 1 anggota.')),
        );
        return;
      }
      
      final newActivity = {
        'name': _activityNameController.text.trim(),
        'date': DateFormat('dd MMMM yyyy').format(_selectedDate),
        'members': _selectedMembers,
      };

      // TODO: Navigasi ke Bill Review/Scan Screen dengan membawa data newActivity
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktivitas dibuat. Lanjut ke Bill Review.')),
      );
      
      // Contoh: Navigator.push(context, MaterialPageRoute(builder: (context) => BillReviewScreen(activityData: newActivity)));
    }
  }

  // Helper Widget untuk Input Field
  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color inputFieldColor = Color(0xFF1B2A41);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black), // Teks input hitam agar kontras dengan background putih
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white, // Background putih seperti di mockup
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama kegiatan wajib diisi.';
        }
        return null;
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);
    
    // Format tanggal sesuai mockup: "17 Agustus 2024"
    final String formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text('Buat Aktivitas Baru', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, // AppBar Putih
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Stack(
        children: [
          // --- 1. Content Form ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Nama Aktivitas Label
                  const Text('Nama Aktivitas', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Input Nama Aktivitas
                  _buildInputField(
                    hint: 'Contoh: Makan Malam Angkatan',
                    controller: _activityNameController,
                  ),
                  const SizedBox(height: 25),

                  // Tanggal Aktivitas
                  const Text('Tanggal Aktivitas', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: primaryColor),
                      title: Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Ubah', style: TextStyle(color: primaryColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Anggota Aktivitas Label
                  const Text('Anggota Aktivitas', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Input Pencarian Anggota & Tombol Tambah
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberSearchController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Cari nama teman...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 50, // Agar sejajar dengan input field
                        child: ElevatedButton(
                          onPressed: _addMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // List Anggota yang Ditambahkan (Tags)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _selectedMembers.map((member) => Chip(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      label: Text(member, style: const TextStyle(color: Colors.black)),
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                      onDeleted: () => _removeMember(member),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Status Anggota Minimal
                  Text(
                    '* minimal 1 anggota untuk lanjut',
                    style: TextStyle(color: _selectedMembers.isEmpty ? Colors.red : Colors.green, fontSize: 12),
                  ),
                  const SizedBox(height: 80), // Jarak untuk tombol Lanjut di bawah
                ],
              ),
            ),
          ),
          
          // --- 2. Tombol Lanjut (Fixed Bottom) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white, // Background putih untuk tombol
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: SafeArea( // Melindungi dari area sistem bawah
                child: ElevatedButton.icon(
                  onPressed: _continueActivity,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('Lanjut', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50), // Lebar penuh
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
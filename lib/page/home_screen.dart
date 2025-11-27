import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan nama user
// import './create_activity_screen.dart'; // Untuk navigasi ke pembuatan grup

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data tiruan (mock data) untuk menampung kegiatan
  List<Map<String, dynamic>> _activeActivities = [
    {
      'name': 'Makan Malam',
      'total_bill': 250000.0,
      'status': '3 orang belum lunas',
      'date': '15 Des 2023',
      'is_paid': false,
    },
    {
      'name': 'Nonton Bioskop',
      'total_bill': 150000.0,
      'status': 'Lunas',
      'date': '12 Des 2023',
      'is_paid': true,
    },
    {
      'name': 'Liburan Bali',
      'total_bill': 3500000.0,
      'status': 'Menunggu 1 pembayaran',
      'date': '01 Nov 2023',
      'is_paid': false,
    },
  ];

  final String _userName =
      FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ??
      'Pengguna';

  void _navigateAndCreateActivity(BuildContext context) async {
    // Navigasi ke layar pembuatan kegiatan
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const CreateActivityScreen()),
    // );
    // TODO: Di sini seharusnya ada logic untuk me-refresh data dari Firestore
  }

  // Helper Widget untuk setiap item aktivitas
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    const Color inputFieldColor = Color(0xFF1B2A41);
    const Color primaryColor = Color(0xFF3B5BFF);
    final bool isPaid = activity['is_paid'];

    // Warna status
    final Color statusColor = isPaid ? Colors.green : Colors.orange;

    return Card(
      color: inputFieldColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          activity['name']!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rp ${activity['total_bill']!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activity['date']!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigasi ke Activity Detail Screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Membuka detail: ${activity['name']}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF0D172A);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      // Hapus AppBar karena kita akan menggunakan custom header di Body
      body: Stack(
        children: [
          // --- 1. Content List ---
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 100,
            ), // Padding bawah untuk tombol FAB
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header Greeting ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Halo $_userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Ikon Notifikasi (Mirip dengan desain)
                    IconButton(
                      icon: const Icon(
                        Icons.group_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        // Navigasi ke tab Notifikasi, atau set index 1 di DashboardScreen
                        // Karena ini ada di dalam DashboardScreen, kita bisa navigasi atau set state Dashboard
                        // Untuk saat ini, hanya Notifikasi
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Membuka Notifikasi...'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Judul Daftar Aktivitas
                const Text(
                  'Daftar Aktivitas Sebelumnya',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),

                // Daftar Kegiatan
                ListView.builder(
                  shrinkWrap: true, // Wajib di dalam SingleChildScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // Wajib di dalam SingleChildScrollView
                  itemCount: _activeActivities.length,
                  itemBuilder: (context, index) {
                    return _buildActivityCard(_activeActivities[index]);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // --- 2. Floating Button: Buat Aktivitas Baru (Sesuai Desain Mockup) ---
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                onPressed: () => _navigateAndCreateActivity(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Buat Aktivitas Baru',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical:15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:splitify/presentation/screens/auth/login_page.dart';
import 'package:splitify/presentation/screens/auth/signup_page.dart';
import 'package:splitify/services/user_service.dart';
import 'package:splitify/presentation/screens/profile/account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _userData;

  // Color scheme
  static const Color darkBlue = Color(0xFF000518);
  static const Color primaryColor = Color(0xFF3B5BFF);
  static const Color cardColor = Color(0xFF1A1F2E);
  static const Color dividerColor = Color(0xFF2A3142);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _userData = null;
          _errorMessage = null;
        });
        return;
      }

      final userDocRef = _firestore.collection('users').doc(currentUser.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        debugPrint(
          '[ProfileScreen] Dokumen belum ada, membuat dokumen default untuk ${currentUser.uid}',
        );

        final email = currentUser.email?.toLowerCase().trim() ?? '';

        final defaultData = {
          'email': email,
          'name': currentUser.displayName ?? 'User',
          'friends': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        };

        await userDocRef.set(defaultData);

        setState(() {
          _userData = {...defaultData, 'uid': currentUser.uid};
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      final data = userDoc.data()!;
      data['uid'] = currentUser.uid;

      final friendUids = await _userService.getFriends();
      final List<Map<String, dynamic>> friendsData = [];
      for (final fUid in friendUids) {
        final fDoc = await _firestore.collection('users').doc(fUid).get();
        if (!fDoc.exists) continue;

        final fData = fDoc.data()!;
        fData['uid'] = fUid;
        friendsData.add(fData);
      }

      setState(() {
        _userData = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToSignup() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfileData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContentBasedOnAuth(),
    );
  }

  Widget _buildContentBasedOnAuth() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return _buildGuestView();
    }
    return _buildProfileContent();
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kamu Belum Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Masuk untuk melihat profil, daftar teman,\ndan mengelola pengaturan akunmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _goToSignup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Daftar (Sign Up)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _auth.currentUser;
    if (user == null || _userData == null) {
      return const Center(
        child: Text('User belum login.', style: TextStyle(color: Colors.white)),
      );
    }

    final displayName = _userData!['name'] ?? user.displayName ?? 'User';
    final email = _userData!['email'] ?? user.email ?? '-';
    final photoUrl = _userData!['photoUrl'] ?? user.photoURL;

    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: primaryColor,
      backgroundColor: cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dividerColor),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar with edit button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 3,
                          ),
                          color: primaryColor.withOpacity(0.2),
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: photoUrl == null
                            ? Text(
                                initials.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Management Section
            _buildSectionTitle('Account Management'),
            const SizedBox(height: 12),
            _buildSectionCard(
              children: [
                _buildRowItem(
                  icon: Icons.person_outline,
                  iconBgColor: primaryColor.withOpacity(0.15),
                  iconColor: primaryColor,
                  title: 'Account Settings',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountSettingsScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadProfileData();
                    }
                  },
                ),
                _buildDivider(),
                _buildRowItem(
                  icon: Icons.notifications_none,
                  iconBgColor: primaryColor.withOpacity(0.15),
                  iconColor: primaryColor,
                  title: 'Notification Settings',
                  onTap: () {
                    // TODO: Navigate to Notification Settings
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security & Privacy Section
            _buildSectionTitle('Security & Privacy'),
            const SizedBox(height: 12),
            _buildSectionCard(
              children: [
                _buildRowItem(
                  icon: Icons.lock_outline,
                  iconBgColor: primaryColor.withOpacity(0.15),
                  iconColor: primaryColor,
                  title: 'Privacy Settings',
                  onTap: () {
                    // TODO: Navigate to Privacy Settings
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle('Support'),
            const SizedBox(height: 12),
            _buildSectionCard(
              children: [
                _buildRowItem(
                  icon: Icons.help_outline,
                  iconBgColor: primaryColor.withOpacity(0.15),
                  iconColor: primaryColor,
                  title: 'Help & Support',
                  onTap: () {
                    // TODO: Navigate to Help & Support
                  },
                ),
                _buildDivider(),
                _buildRowItem(
                  icon: Icons.info_outline,
                  iconBgColor: primaryColor.withOpacity(0.15),
                  iconColor: primaryColor,
                  title: 'Terms of Service',
                  onTap: () {
                    // TODO: Navigate to Terms of Service
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }
}

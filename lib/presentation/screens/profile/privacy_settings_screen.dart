import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isPublicProfile = true;
  bool _showActivityStatus = true;

  static const Color darkBlue = Color(0xFF000518);
  static const Color cardColor = Color(0xFF1A1F2E);
  static const Color primaryColor = Color(0xFF3B5BFF);
  static const Color dividerColor = Color(0xFF2A3142);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Privacy Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _isPublicProfile,
                  activeColor: primaryColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: const Text(
                    'Public Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Allow others to find your profile',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _isPublicProfile = val);
                  },
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                SwitchListTile(
                  value: _showActivityStatus,
                  activeColor: primaryColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: const Text(
                    'Show Activity Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Let friends see when you are active',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _showActivityStatus = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

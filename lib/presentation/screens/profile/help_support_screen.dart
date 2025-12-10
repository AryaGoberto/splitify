import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Contact Us',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Get help from our support team',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  onTap: () {
                    // TODO: Implement contact action
                  },
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.question_answer_outlined,
                      color: primaryColor,
                    ),
                  ),
                  title: const Text(
                    'FAQ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Find answers to common questions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  onTap: () {
                    // TODO: Implement FAQ navigation
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

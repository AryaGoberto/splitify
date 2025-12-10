import 'package:flutter/material.dart';

class TosScreen extends StatefulWidget {
  const TosScreen({super.key});

  @override
  State<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends State<TosScreen> {
  final String _tosContent = '''
TERMS OF SERVICE
Last updated: January 01, 2025

Please read these terms and conditions carefully before using Our Service.


INTERPRETATION AND DEFINITIONS

Interpretation
The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.

Definitions
For the purposes of these Terms and Conditions:

- Application means the software program provided by the Company downloaded by You on any electronic device.
- Application Store means the digital distribution service operated and developed by Apple Inc. (Apple App Store) or Google Inc. (Google Play Store).
- Affiliate means an entity that controls, is controlled by, or is under common control with a party.
- Account means a unique account created for You to access our Service.
- Company refers to Splitify Inc.
- Country refers to: United States.
- Content refers to content such as text, images, or other information that can be posted, uploaded, linked, or otherwise made available by You.
- Device means any device that can access the Service such as a computer, cellphone, or tablet.
- Service refers to the Application or the Website.
- Subscriptions refer to paid plans for accessing premium features.
- Website refers to Splitify, accessible from https://www.splitify.com
- You means the individual accessing or using the Service.


ACKNOWLEDGMENT

These Terms govern the use of this Service and constitute the agreement between You and the Company. Your access to and use of the Service is conditioned on Your acceptance of these Terms. By using the Service, You agree to be bound by these Terms.

If You disagree with any part of these Terms, then You may not access the Service.


SUBSCRIPTIONS

Some parts of the Service are billed on a subscription basis. You will be billed in advance on a recurring basis depending on your selected plan.


CONTENT

You are responsible for the Content that You post. You represent and warrant that the Content is yours and does not infringe on any third party rights.


COPYRIGHT POLICY

We respect the intellectual property rights of others. If You believe your copyrighted work has been infringed, please notify us.


INTELLECTUAL PROPERTY

The Service and its original content, features, and functionality are and will remain the exclusive property of the Company.


USER ACCOUNTS

When You create an account, You must provide accurate and complete information. Failure to do so may result in termination of your account.


TERMINATION

We may terminate or suspend Your account immediately, without prior notice or liability, for any reason, including breach of these Terms.


LIMITATION OF LIABILITY

To the maximum extent permitted by law, the Company shall not be liable for any indirect, incidental, special, or consequential damages.


DISCLAIMER

The Service is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind.


GOVERNING LAW

The laws of the Country shall govern these Terms.


CHANGES TO THESE TERMS

We reserve the right to modify these Terms at any time. You are advised to review this page periodically.


CONTACT US

If you have any questions about these Terms, You can contact us at:

Email: support@splitify.com
''';

  static const Color darkBlue = Color(0xFF000518);
  static const Color cardColor = Color(0xFF1A1F2E);
  // static const Color primaryColor = Color(0xFF3B5BFF);
  // static const Color dividerColor = Color(0xFF2A3142);

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
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _tosContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

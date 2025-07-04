import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _buildFAQItem(
              'How can I verify my account?',
              'To verify your account, go to the "Profile" section and submit the required verification details. Adults need to provide citizenship details, and minors need to provide school ID details. An admin will review your submission and mark your account as verified if the details are accurate.',
            ),
            _buildFAQItem(
              'What happens if my account is not verified?',
              'If your account is not verified, you will be notified and asked to resubmit the necessary details. You will not be able to report a complaint until your account is verified. Make sure to provide accurate and complete information to avoid any delays in the verification process.',
            ),
            _buildFAQItem(
              'How do I report a road issue?',
              'To report a road issue, go to the register complaint page and fill all the form fields. Then hit submit to report the issue.',
            ),
            _buildFAQItem(
              'How long does it take for an issue to be resolved?',
              'Resolution times vary depending on the nature and severity of the issue. We typically aim to address critical issues as soon as possible.',
            ),
            _buildFAQItem(
              'Can I track the status of my complaint?',
              'Yes, you can track the status of your complaint in the "Track Complaint" section of the app.',
            ),
            _buildFAQItem(
              'What should I do if I encounter an emergency road issue?',
              'For emergency road issues, please contact our emergency hotline immediately after submitting the complaint through the app.',
            ),
            _buildFAQItem(
              'How can I provide additional information about an issue?',
              'You can provide additional information by updating your complaint in the "My Complaints" section or by contacting our support team.',
            ),
            _buildFAQItem(
              'What types of road issues can I report?',
              'You can report various types of road issues such as potholes, road damage, obstructions, and traffic signal malfunctions.',
            ),
            // Add more FAQ items as needed
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}

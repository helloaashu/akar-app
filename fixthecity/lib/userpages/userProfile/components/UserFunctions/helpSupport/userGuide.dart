import 'package:flutter/material.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text('User Guide', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.deepPurple,
      iconTheme: IconThemeData(color: Colors.white),
    ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Welcome to Road Issues Complaint App',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This guide will help you navigate and use our app effectively:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            _buildGuideSection(
              context,
              title: '1. Reporting an Issue',
              steps: [
                'Before reporting an issue, you must complete your profile by submitting your verification details:',
                'Adults need to provide their citizenship details.',
                'Minors need to provide their school ID details.',
                'Once submitted, an admin will review your details. If all the details are accurate, you will be marked as verified. If not, you will be notified to resubmit your details. Only verified users can submit complaints.',
                'Tap on "Register Complaint" from the main screen.',
                'Select the type of issue from the list.',
                'Take or upload a photo of the issue.',
                'Provide additional details and your location.',
                'Submit the report.',
              ],
            ),
            _buildGuideSection(
              context,
              title: '2. Tracking Your Reports',
              steps: [
                'Go to "Track Complaint" to see all your submitted issues.',
                'Go to "Complaint History" to view the current status and any updates.',
              ],
            ),
            _buildGuideSection(
              context,
              title: '3. Contacting Support',
              steps: [
                'If you need further assistance, go to the "Help & Support" section.',
                'You can find FAQs, user guides, and options to contact support.',
              ],
            ),
            _buildGuideSection(
              context,
              title: '4. Updating Your Profile',
              steps: [
                'Go to "Profile" from the main menu.',
                'Update your personal details and preferences.',
                'Make sure to save changes before exiting.',
              ],
            ),
            // Add more sections as needed
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(BuildContext context, {required String title, required List<String> steps}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            int idx = entry.key;
            String step = entry.value;
            return Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  idx == 0 ? SizedBox() : Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
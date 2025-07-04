import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helpSupport/FAQpage.dart';
import 'helpSupport/ReportProblem.dart';
import 'helpSupport/userGuide.dart';

class HelpAndSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _buildSectionHeader('Help'),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'FAQ',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQPage()),
              ),
            ),
            _buildListTile(
              icon: Icons.book,
              title: 'User Guide',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserGuidePage()),
              ),
            ),
            Divider(),
            _buildSectionHeader('Support'),
            _buildListTile(
              icon: Icons.contact_support,
              title: 'Contact Support',
              onTap: _launchEmail,
            ),
            _buildListTile(
              icon: Icons.report_problem,
              title: 'Report a Problem',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportProblemPage()),
              ),
            ),
            Divider(),
            _buildSectionHeader('About'),
            _buildListTile(
              icon: Icons.update,
              title: 'App Version',
              subtitle: '1.0.0', onTap: () {  }, // Replace with your actual app version
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      tileColor: Colors.white,
      selectedTileColor: Colors.grey[200],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@roadissuescomplaint.com',
      query: Uri.encodeFull('subject=Support Request for Road Issues Complaint App'),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }
}

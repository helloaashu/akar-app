import 'package:fixthecity/userpages/userProfile/components/UserFunctions/perosnalDetails.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/settings/changePasswordPage.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/settings/privacyPolicy.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/settings/termsService.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Screens/home.dart';

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  bool pushNotifications = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            'Account',
            [
              _buildListTile(
                'Edit Profile',
                Icons.person_outline,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PersonalInformationPage()),
                  );
                },
                    () {
                  print('Edit Profile icon tapped');
                  // Add custom logic for icon tap
                },
              ),
              _buildListTile(
                'Change Password',
                Icons.lock_outline,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                  );
                },
                    () {
                  print('Change Password icon tapped');
                  // Add custom logic for icon tap
                },
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                'Push Notifications',
                Icons.notifications_none,
                pushNotifications,
                    (bool value) {
                  setState(() {
                    pushNotifications = value;
                  });
                  // Handle push notifications toggle
                },
                    () {
                  print('Push Notifications icon tapped');
                  // Add custom logic for icon tap
                },
              ),
              _buildSwitchTile(
                'Email Notifications',
                Icons.email_outlined,
                emailNotifications,
                    (bool value) {
                  setState(() {
                    emailNotifications = value;
                  });
                  // Handle email notifications toggle
                },
                    () {
                  print('Email Notifications icon tapped');
                  // Add custom logic for icon tap
                },
              ),
            ],
          ),
          _buildSection(
            'More',
            [
              _buildListTile(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>PrivacyPolicyScreen()),
                  );
                },
                    () {
                  print('Privacy Policy icon tapped');
                  // Add custom logic for icon tap
                },
              ),
              _buildListTile(
                'Terms of Service',
                Icons.description_outlined,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TermsOfServiceScreen()),
                  );
                },
                    () {
                  print('Terms of Service icon tapped');
                  // Add custom logic for icon tap
                },
              ),
              // Uncomment this section if you want to include the Log Out option
              // _buildListTile(
              //   'Log Out',
              //   Icons.exit_to_app,
              //   () async {
              //     await signOut(context);
              //   },
              //   () {
              //     print('Log Out icon tapped');
              //     // Add custom logic for icon tap
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap, VoidCallback onIconTap) {
    return ListTile(
      leading: InkWell(
        onTap: onIconTap,
        child: Icon(icon),
      ),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
      String title, IconData icon, bool value, ValueChanged<bool> onChanged, VoidCallback onIconTap) {
    return ListTile(
      leading: InkWell(
        onTap: onIconTap,
        child: Icon(icon),
      ),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// Future<void> signOut(BuildContext context) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.remove('userId');
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (context) => MyHome()),
//         (Route<dynamic> route) => false,
//   );
// }
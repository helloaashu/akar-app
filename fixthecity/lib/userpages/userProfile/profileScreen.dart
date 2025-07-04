import 'package:fixthecity/admin/settings_page.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/feedbackPage.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/helpSupport.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/invite_page.dart';
import 'package:fixthecity/userpages/userProfile/components/UserFunctions/settingPage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'components/UserFunctions/perosnalDetails.dart';
import 'components/profileMenu.dart';
import 'components/profilePic.dart';
import 'components/completeProfile.dart';
import 'package:shimmer/shimmer.dart';

enum VerificationStatus {
  pending,
  verified,
  unverified,
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  VerificationStatus verificationStatus = VerificationStatus.pending;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final status = doc.data()?['verificationStatus'] ?? 'pending';
      if (mounted) {
        setState(() {
          verificationStatus = VerificationStatus.values.firstWhere(
                (e) => e.toString() == 'VerificationStatus.$status',
            orElse: () => VerificationStatus.pending,
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 2),
            const ProfilePic(),
            const SizedBox(height: 2),
            if (verificationStatus != VerificationStatus.verified)
            const Cprofile(),
            if (verificationStatus == VerificationStatus.verified) ...[
              const SizedBox(height: 14),
              _isLoading
                  ? Shimmer.fromColors( // Show shimmer while loading
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                enabled: true,
                child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(
                    5,
                        (index) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: Colors.grey),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 16,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  ProfileMenu(
                    text: "Personal Information",
                    icon: const Icon(Icons.person_outline,
                        color: Colors.deepPurple),
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PersonalInformationPage()),
                      );
                    },
                  ),
                  ProfileMenu(
                    text: "Settings",
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.deepPurple),
                    press: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserSettingsPage()),
                      );

                    },
                  ),
                  ProfileMenu(
                    text: "Invite a Friend",
                    icon: const Icon(Icons.person_add_alt_1_outlined,
                        color: Colors.deepPurple),
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InvitePage()),
                      );
                    },
                  ),
                  ProfileMenu(
                    text: "Feedback",
                    icon: const Icon(Icons.feedback_outlined,
                        color: Colors.deepPurple),
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FeedbackPage()),
                      );

                    },
                  ),
                  ProfileMenu(
                    text: "Help & Support",
                    icon: const Icon(Icons.help_outline_outlined,
                        color: Colors.deepPurple),
                    press: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpAndSupportPage()),
                      );

                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
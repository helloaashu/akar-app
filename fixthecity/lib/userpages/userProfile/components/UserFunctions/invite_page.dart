import 'package:flutter/material.dart';
import 'package:share/share.dart';

class InvitePage extends StatefulWidget {
  @override
  _InvitePageState createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final TextEditingController _emailController = TextEditingController();

  void _inviteByEmail() {
    final String shareText =
        'Hi, I am using this amazing app to report road maintenance issues. Join me by clicking this link: [AKAR App Link]';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [
          // Background Image
          Container(
            height: MediaQuery.of(context).size.height * 0.4, // Reduced height
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/invite.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0), // Added top padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Invite your friends, \nFix our streets: Repairing Our Roads for a Better Community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3c1414),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'For every new friend that joins, you both unlock exclusive Road Guardian PERKS!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF000060),
                    ),
                  ),
                  const Spacer(), // This will push the button to the bottom
                  ElevatedButton(
                    onPressed: _inviteByEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text(
                      'SEND INVITE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20), // Added bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

import 'package:fixthecity/Screens/home.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/bdialogs/about_dialog.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/bdialogs/emergency_contacts_dialog.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/bottom_navigation.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/bservices/auth_service.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/bservices/profile_service.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/custom_app_bar.dart';
import 'package:fixthecity/userpages/userProfile/basePageComponents/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Screens/login.dart';


class BasePage extends StatefulWidget {
  final Widget page;
  final int pageIndex;
  final Function(int) onPageChanged;

  const BasePage({
    Key? key,
    required this.page,
    required this.pageIndex,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomAboutDialog(),
    );
  }

  void _showEmergencyContactsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => EmergencyContactsDialog(),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Do you want to exit the app?', style: TextStyle(fontSize: 18)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldExit ?? false) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: CustomAppBar(
          pageIndex: widget.pageIndex,
          profileService: _profileService,
        ),
        drawer: CustomDrawer(
          onPageChanged: widget.onPageChanged,
          onShowEmergencyContacts: _showEmergencyContactsDialog,
          onShowAbout: _showAboutDialog,
          onSignOut: () => _authService.signOut(context),
        ),
        body: widget.page,
        bottomNavigationBar: CustomBottomNavigation(
          pageIndex: widget.pageIndex,
          onPageChanged: widget.onPageChanged,
        ),
      ),
    );
  }
}
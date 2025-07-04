import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Screens/home.dart';


class AuthService {
  Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyHome()),
          (Route<dynamic> route) => false,
    );
  }
}
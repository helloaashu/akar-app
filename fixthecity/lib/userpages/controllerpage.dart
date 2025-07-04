import "package:fixthecity/userpages/Home/HomePage.dart";
import "package:fixthecity/userpages/profilepage.dart";
import "package:fixthecity/userpages/userProfile/profileScreen.dart";
import "package:flutter/material.dart";
import "../Screens/feedScreen.dart";
import "basePage.dart";
// Import the BasePage widget

import "../Screens/login.dart";
import "complaintForms/enhancedComplaint.dart";
import "homepage.dart";
import "messagepage.dart";

class MyCont extends StatefulWidget {

  const MyCont({super.key});

  @override
  State<MyCont> createState() => _MyContState();
}

class _MyContState extends State<MyCont> {
  int page = 0;

  late final List<Widget> _pages = [

    UserHomePage(onPageChanged: _onPageChanged,),
    EnhancedComplaintForm(),
   // RegisterComplaintForm(),
    //ComplaintFeedScreen(),
    EnhancedComplaintFeedScreen(),

    //NotificationsPage(),
    //UserProfile(),
    ProfileScreen(),

  ];

  void _onPageChanged(int index) {
    setState(() {
      page = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    int safeIndex = page.clamp(0, _pages.length - 1); // avoids crash

    return BasePage(
      page: _pages[safeIndex],
      pageIndex: safeIndex,
      onPageChanged: _onPageChanged,
    );
  }

}
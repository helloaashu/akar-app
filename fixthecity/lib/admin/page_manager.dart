import 'package:fixthecity/userpages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:ui';

import '../userpages/basePage.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'users_page.dart';

class PageManager extends StatefulWidget {
  @override
  _PageManagerState createState() => _PageManagerState();
}

class _PageManagerState extends State<PageManager> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    AdminHomePage(),
    SearchPage(),
    SettingsPage(),
    UsersPage(),
  ];

  static final List<String> _titles = <String>[
    'Dashboard',
    'Search',
    'Settings',
    'Users',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // SignOut function implementation
  Future<void> signOut(BuildContext context) async {
    try {
      // Method 1: If using Firebase Auth
      // await FirebaseAuth.instance.signOut();

      // Method 2: If using SharedPreferences for storing login state
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear(); // or remove specific keys
      // await prefs.setBool('isLoggedIn', false);
      // await prefs.remove('userToken');

      // Method 3: If using a state management solution (Provider, Riverpod, etc.)
      // Provider.of<AuthProvider>(context, listen: false).signOut();

      // Navigate to login page and clear the navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home', // Replace with your login route
            (route) => false,
      );

      // Alternative navigation if you don't have named routes:
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => LoginPage()),
      //   (route) => false,
      // );

    } catch (e) {
      // Handle any errors during sign out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Confirm Logout'),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await signOut(context); // Perform logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A5ACD),
                Color(0xFF9370DB),
                Color(0xFFBA55D3),
              ],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 28),
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6A5ACD).withOpacity(0.9),
                    Color(0xFF9370DB).withOpacity(0.8),
                    Color(0xFFBA55D3).withOpacity(0.7),
                    Color(0xFFDDA0DD).withOpacity(0.6),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Admin Profile Header
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: ClipOval(
                              child: Image.asset(
                                "assets/Akar_logo.png",
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.admin_panel_settings,
                                    size: 50,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Smart Community',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildDrawerItem(
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard,
                          title: "Dashboard",
                          index: 0,
                          isSelected: _selectedIndex == 0,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(0);
                          },
                        ),
                        SizedBox(height: 8),
                        _buildDrawerItem(
                          icon: Icons.search_outlined,
                          selectedIcon: Icons.search,
                          title: "Search",
                          index: 1,
                          isSelected: _selectedIndex == 1,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(1);
                          },
                        ),
                        SizedBox(height: 8),
                        _buildDrawerItem(
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings,
                          title: "Settings",
                          index: 2,
                          isSelected: _selectedIndex == 2,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(2);
                          },
                        ),
                        SizedBox(height: 8),
                        _buildDrawerItem(
                          icon: Icons.people_outline,
                          selectedIcon: Icons.people,
                          title: "Users",
                          index: 3,
                          isSelected: _selectedIndex == 3,
                          onTap: () {
                            Navigator.pop(context);
                            _onItemTapped(3);
                          },
                        ),
                        SizedBox(height: 30),

                        // Divider
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Additional Options
                        _buildDrawerItem(
                          icon: Icons.analytics_outlined,
                          selectedIcon: Icons.analytics,
                          title: "Analytics",
                          onTap: () {
                            Navigator.pop(context);
                            // Add analytics navigation
                          },
                        ),
                        SizedBox(height: 8),
                        _buildDrawerItem(
                          icon: Icons.help_outline,
                          selectedIcon: Icons.help,
                          title: "Help & Support",
                          onTap: () {
                            Navigator.pop(context);
                            // Add help navigation
                          },
                        ),
                      ],
                    ),
                  ),

                  // Logout Section
                  Container(
                    padding: EdgeInsets.all(20),
                    child: _buildDrawerItem(
                      icon: Icons.logout_outlined,
                      selectedIcon: Icons.logout,
                      title: "Logout",
                      isLogout: true,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        _showLogoutDialog(); // Show confirmation dialog
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A5ACD),
              Color(0xFF9370DB),
              Color(0xFFBA55D3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
          child: GNav(
            gap: 8,
            backgroundColor: Colors.transparent,
            color: Colors.white70,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.white.withOpacity(0.2),
            padding: EdgeInsets.all(17),
            duration: Duration(milliseconds: 300),
            tabs: const [
              GButton(
                icon: Icons.dashboard_outlined,
                text: "Home",
              ),
              GButton(
                icon: Icons.search,
                text: "Search",
              ),
              GButton(
                icon: Icons.settings,
                text: "Settings",
              ),
              GButton(
                icon: Icons.people,
                text: "Users",
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              _onItemTapped(index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    int? index,
    bool isSelected = false,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isSelected
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
        border: isSelected
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLogout
                        ? Colors.red.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: isLogout ? Colors.red[300] : Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLogout ? Colors.red[300] : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
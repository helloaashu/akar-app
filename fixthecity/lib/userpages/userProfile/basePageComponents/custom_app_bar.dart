import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Notification.dart';
import 'bservices/profile_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int pageIndex;
  final ProfileService profileService;

  const CustomAppBar({
    Key? key,
    required this.pageIndex,
    required this.profileService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pageIndex == 0) {
      return _buildHomeAppBar(context);
    } else {
      return _buildDefaultAppBar(context);
    }
  }

  AppBar _buildHomeAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.deepPurple),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            iconSize: 28.0,
          );
        },
      ),
      actions: [
        Row(
          children: [
            _buildNotificationButton(context),
            _buildProfileAvatar(),
          ],
        ),
      ],
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      title: _getTitle(pageIndex),
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(
        icon: const Icon(Icons.notifications_on, color: Colors.deepPurple),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Message()),
          );
        },
        iconSize: 28.0,
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: 40,
        height: 40,
        child: _buildAvatarBasedOnUserType(),
      ),
    );
  }

  Widget _buildAvatarBasedOnUserType() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Check if user is signed in with Google
    if (currentUser != null && _isGoogleUser(currentUser)) {
      return _buildGoogleUserAvatar(currentUser);
    } else {
      return _buildRegularUserAvatar();
    }
  }

  bool _isGoogleUser(User user) {
    // Check if user has Google provider
    return user.providerData.any((provider) => provider.providerId == 'google.com');
  }

  Widget _buildGoogleUserAvatar(User user) {
    // For Google users, always use fresh photoURL directly
    final String? photoURL = user.photoURL;

    if (photoURL != null && photoURL.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(
          photoURL,
          // Add cache-busting parameter to ensure fresh data
          headers: {'Cache-Control': 'no-cache'},
        ),
        backgroundColor: Colors.deepPurple,
        onBackgroundImageError: (exception, stackTrace) {
          // Handle image loading errors
          print('Error loading Google profile image: $exception');
        },
      );
    } else {
      // Fallback if Google user doesn't have a photo
      return CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Text(
          user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildRegularUserAvatar() {
    // For non-Google users, use cached profile images from Firestore
    return FutureBuilder<String?>(
      future: profileService.getProfileImageURL(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            backgroundImage: NetworkImage(snapshot.data!),
            backgroundColor: Colors.deepPurple,
          );
        } else {
          return const CircleAvatar(
            backgroundImage: AssetImage("assets/Profile Image.png"),
          );
        }
      },
    );
  }

  Text _getTitle(int pageIndex) {
    switch (pageIndex) {
      case 1:
        return const Text("Smart Complaint Form",
            style: TextStyle(fontSize: 20, color: Colors.white));
      case 2:
        return const Text("My Feed",
            style: TextStyle(fontSize: 20, color: Colors.white));
      case 3:
        return const Text("My Profile",
            style: TextStyle(fontSize: 20, color: Colors.white));
      default:
        return const Text("App",
            style: TextStyle(fontSize: 20, color: Colors.white));
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
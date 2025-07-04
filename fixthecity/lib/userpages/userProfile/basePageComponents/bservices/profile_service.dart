import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get profile image URL based on user type
  Future<String?> getProfileImageURL() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Check if user is signed in with Google
        if (_isGoogleUser(user)) {
          // For Google users, return the fresh photoURL directly
          return user.photoURL;
        } else {
          // For regular users, get cached image from Firestore
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            return (userDoc.data() as Map<String, dynamic>)['profileImageURL'] as String?;
          }
        }
      }
    } catch (e) {
      print('Error fetching profile image URL: $e');
    }
    return null;
  }

  /// Get user display name based on user type
  Future<String?> getDisplayName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (_isGoogleUser(user)) {
          // For Google users, use displayName directly
          return user.displayName;
        } else {
          // For regular users, get name from Firestore
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
            return data['displayName'] ?? data['name'];
          }
        }
      }
    } catch (e) {
      print('Error getting display name: $e');
    }
    return null;
  }

  /// Check if current user is a Google user
  bool _isGoogleUser(User user) {
    return user.providerData.any((provider) => provider.providerId == 'google.com');
  }

  /// Check if current user is Google user (public method)
  bool isCurrentUserGoogleUser() {
    final User? currentUser = _auth.currentUser;
    return currentUser != null && _isGoogleUser(currentUser);
  }
}
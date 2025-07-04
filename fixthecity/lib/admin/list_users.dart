import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.deepPurple,
      ),
      home: UsersPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class User {
  final String id;
  final String name;
  final String contact;
  final String email;
  final String? profileImageURL;
  final String verificationStatus;
  final String? citizenshipNumber;
  final String? idImageURL;
  final bool isGovIdUploaded;
  final bool isProfileCompleted;

  User({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    this.profileImageURL,
    required this.verificationStatus,
    this.citizenshipNumber,
    this.idImageURL,
    required this.isGovIdUploaded,
    required this.isProfileCompleted,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      name: data['name'] is String ? data['name'] : '',
      contact: data['contact'] is String ? data['contact'] : '',
      email: data['email'] is String ? data['email'] : '',
      profileImageURL: data.containsKey('profileImageURL') && data['profileImageURL'] is String ? data['profileImageURL'] : null,
      verificationStatus: data.containsKey('verificationStatus') && data['verificationStatus'] is String ? data['verificationStatus'] : 'pending',
      citizenshipNumber: data.containsKey('citizenshipNumber') && data['citizenshipNumber'] is String ? data['citizenshipNumber'] : null,
      idImageURL: data.containsKey('idImageURL') && data['idImageURL'] is String ? data['idImageURL'] : null,
      isGovIdUploaded: data.containsKey('isGovIdUploaded') && data['isGovIdUploaded'] is bool ? data['isGovIdUploaded'] : false,
      isProfileCompleted: data.containsKey('isProfileCompleted') && data['isProfileCompleted'] is bool ? data['isProfileCompleted'] : false,
    );
  }
}

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchScaleAnimation;
  bool _isSearchFocused = false;
  bool _isConnected = true; // Firebase connection status

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _searchScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.elasticOut),
    );

    _fetchUsers();
    _animationController.forward();
  }

  void _fetchUsers() async {
    // Listen to real-time updates from Firestore
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      List<User> users = snapshot.docs.map((doc) => User.fromDocument(doc)).toList();

      // Debug: Print counts to console
      print('📊 Real-time Firebase Update:');
      print('   Total users: ${users.length}');
      print('   Verified users: ${users.where((u) => u.verificationStatus == 'verified').length}');
      print('   Pending users: ${users.where((u) => u.verificationStatus == 'pending').length}');
      print('   Other statuses: ${users.where((u) => u.verificationStatus != 'verified' && u.verificationStatus != 'pending').length}');

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isConnected = true;
      });
    }, onError: (error) {
      print('❌ Error fetching users: $error');
      setState(() {
        _isConnected = false;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection lost. Retrying...'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user.name.toLowerCase().startsWith(query) ||
            user.contact.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    _animationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0033),
              Color(0xFF330066),
              Color(0xFF4A0080),
              Color(0xFF6600CC),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildUserStats(),
              Expanded(child: _buildUserList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8A2BE2).withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6FA)],
                        ).createShader(bounds),
                        child: Text(
                          'Users',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Real-time connection indicator
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isConnected ? Color(0xFF00C851) : Color(0xFFFF6B6B),
                          boxShadow: [
                            BoxShadow(
                              color: (_isConnected ? Color(0xFF00C851) : Color(0xFFFF6B6B)).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isConnected ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isConnected ? 'Real-time data • Manage your community' : 'Connection lost • Retrying...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildNotificationIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white24),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Color(0xFFFF6B6B),
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '${_allUsers.where((u) => u.verificationStatus == 'pending').length}',
              style: TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ScaleTransition(
          scale: _searchScaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: _isSearchFocused ? Color(0xFFDA70D6) : Colors.white24,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8A2BE2).withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white, fontSize: 16),
              onTap: () {
                setState(() => _isSearchFocused = true);
                _searchAnimationController.forward();
              },
              onSubmitted: (_) {
                setState(() => _isSearchFocused = false);
                _searchAnimationController.reverse();
              },
              decoration: InputDecoration(
                hintText: 'Search users, emails, contacts...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Color(0xFFDA70D6), size: 24),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _isSearchFocused = false);
                    _searchAnimationController.reverse();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    // Calculate real-time stats
    int totalUsers = _allUsers.length;
    int verifiedUsers = _allUsers.where((u) => u.verificationStatus == 'verified').length;
    int pendingUsers = _allUsers.where((u) => u.verificationStatus == 'pending').length;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('Total', totalUsers.toString(), Icons.people, Color(0xFF8A2BE2))),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('Verified', verifiedUsers.toString(), Icons.verified, Color(0xFF00C851))),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('Pending', pendingUsers.toString(), Icons.pending, Color(0xFFFF8800))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: double.parse(count)),
      builder: (context, value, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse animation for real-time indicator
                  TweenAnimationBuilder<double>(
                    duration: Duration(seconds: 2),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, pulseValue, child) {
                      return Container(
                        width: 40 + (pulseValue * 10),
                        height: 40 + (pulseValue * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.1 * (1 - pulseValue)),
                        ),
                      );
                    },
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: double.parse(count)),
                builder: (context, animatedValue, child) {
                  return Text(
                    animatedValue.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  // Live indicator dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(0xFF00C851),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00C851).withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(top: 10),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: UserCard(
                      user: _filteredUsers[index],
                      index: index,
                      onUserUpdated: () {
                        // Callback to refresh data when user is updated
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// MODULAR COMPONENT: UserCard
class UserCard extends StatefulWidget {
  final User user;
  final int index;
  final VoidCallback onUserUpdated;

  const UserCard({
    Key? key,
    required this.user,
    required this.index,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _showUserDetails() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserDetailsDialog(
          user: widget.user,
          onUserUpdated: widget.onUserUpdated,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _showUserDetails,
              onTapDown: (_) {
                _hoverController.forward();
                setState(() => _isHovered = true);
              },
              onTapUp: (_) {
                _hoverController.reverse();
                setState(() => _isHovered = false);
              },
              onTapCancel: () {
                _hoverController.reverse();
                setState(() => _isHovered = false);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: _isHovered ? Color(0xFFDA70D6) : Colors.white24,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8A2BE2).withOpacity(0.1 + (_elevationAnimation.value * 0.2)),
                      blurRadius: 20 + (_elevationAnimation.value * 10),
                      offset: Offset(0, 5 + (_elevationAnimation.value * 5)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      _buildGlowEffect(),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            _buildProfileImage(),
                            SizedBox(width: 16),
                            Expanded(child: _buildUserInfo()),
                            _buildVerificationButton(),
                          ],
                        ),
                      ),
                      // Clickable indicator
                      if (_isHovered)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color(0xFFDA70D6).withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFDA70D6).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'TAP FOR DETAILS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect() {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: _isHovered ? 0.1 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [
                Color(0xFFDA70D6).withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF8A2BE2).withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: widget.user.profileImageURL != null
              ? ClipOval(
            child: Image.network(
              widget.user.profileImageURL!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            ),
          )
              : _buildDefaultAvatar(),
        ),
        if (widget.user.verificationStatus == 'verified')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Color(0xFF00C851),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
        ),
      ),
      child: Icon(Icons.person, color: Colors.white, size: 30),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.user.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.phone, color: Color(0xFFDA70D6), size: 14),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.user.contact,
                style: TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.email, color: Color(0xFFDA70D6), size: 14),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.user.email,
                style: TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => VerificationStatusDialog(
            user: widget.user,
            onStatusUpdated: widget.onUserUpdated,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: widget.user.verificationStatus == 'verified'
                ? [Color(0xFF00C851), Color(0xFF007E33)]
                : [Color(0xFFFF8800), Color(0xFFCC6600)],
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.user.verificationStatus == 'verified'
                  ? Color(0xFF00C851)
                  : Color(0xFFFF8800)).withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          widget.user.verificationStatus == 'verified' ? Icons.verified : Icons.pending,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// MODULAR COMPONENT: UserDetailsDialog
class UserDetailsDialog extends StatelessWidget {
  final User user;
  final VoidCallback onUserUpdated;

  const UserDetailsDialog({
    Key? key,
    required this.user,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0033),
                  Color(0xFF330066),
                  Color(0xFF4A0080),
                ],
              ),
              border: Border.all(color: Color(0xFFDA70D6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8A2BE2).withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Column(
                children: [
                  _buildDialogHeader(context),
                  Expanded(child: _buildDialogContent()),
                  _buildDialogActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8A2BE2).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: user.profileImageURL != null
                    ? ClipOval(
                  child: Image.network(
                    user.profileImageURL!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultDialogAvatar(),
                  ),
                )
                    : _buildDefaultDialogAvatar(),
              ),
              if (user.verificationStatus == 'verified')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00C851),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00C851).withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.verified, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFE6E6FA)],
                  ).createShader(bounds),
                  child: Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                _buildStatusChip(user.verificationStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultDialogAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
        ),
      ),
      child: Icon(Icons.person, color: Colors.white, size: 35),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;
    switch (status) {
      case 'verified':
        chipColor = Color(0xFF00C851);
        chipIcon = Icons.verified;
        break;
      case 'pending':
        chipColor = Color(0xFFFF8800);
        chipIcon = Icons.pending;
        break;
      default:
        chipColor = Color(0xFFFF6B6B);
        chipIcon = Icons.error;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: chipColor.withOpacity(0.2),
        border: Border.all(color: chipColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: chipColor, size: 16),
          SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(Icons.email, 'Email', user.email),
            _buildInfoRow(Icons.phone, 'Contact', user.contact),
            if (user.citizenshipNumber != null)
              _buildInfoRow(Icons.credit_card, 'Citizenship Number', user.citizenshipNumber!),
          ]),

          SizedBox(height: 24),
          _buildSectionTitle('Verification Status'),
          SizedBox(height: 16),
          _buildVerificationStatusCard(),

          SizedBox(height: 24),
          _buildSectionTitle('Profile Completion'),
          SizedBox(height: 16),
          _buildCompletionCard(),

          if (user.idImageURL != null) ...[
            SizedBox(height: 24),
            _buildSectionTitle('Verification Documents'),
            SizedBox(height: 16),
            _buildDocumentCard(user.idImageURL!),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Color(0xFFDA70D6), Color(0xFF8A2BE2)],
      ).createShader(bounds),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFDA70D6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFFDA70D6), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          _buildStatusIndicator('Government ID Uploaded', user.isGovIdUploaded),
          SizedBox(height: 12),
          _buildStatusIndicator('Profile Completed', user.isProfileCompleted),
          SizedBox(height: 12),
          _buildStatusIndicator('Account Verified', user.verificationStatus == 'verified'),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isComplete) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? Color(0xFF00C851) : Color(0xFFFF6B6B),
            boxShadow: [
              BoxShadow(
                color: (isComplete ? Color(0xFF00C851) : Color(0xFFFF6B6B)).withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isComplete ? Icons.check : Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          isComplete ? 'Complete' : 'Incomplete',
          style: TextStyle(
            color: isComplete ? Color(0xFF00C851) : Color(0xFFFF6B6B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    int completedItems = 0;
    int totalItems = 3;

    if (user.isGovIdUploaded) completedItems++;
    if (user.isProfileCompleted) completedItems++;
    if (user.verificationStatus == 'verified') completedItems++;

    double progress = completedItems / totalItems;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Color(0xFFDA70D6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white24,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '$completedItems of $totalItems steps completed',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String imageUrl) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Color(0xFFDA70D6), size: 24),
              SizedBox(width: 12),
              Text(
                'Government ID Document',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA70D6)),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Color(0xFFFF6B6B), size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Color(0xFF6C757D), Color(0xFF6C757D).withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C757D).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFF8A2BE2).withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8A2BE2).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => VerificationStatusDialog(
                      user: user,
                      onStatusUpdated: onUserUpdated,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Update Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MODULAR COMPONENT: VerificationStatusDialog
class VerificationStatusDialog extends StatelessWidget {
  final User user;
  final VoidCallback onStatusUpdated;

  const VerificationStatusDialog({
    Key? key,
    required this.user,
    required this.onStatusUpdated,
  }) : super(key: key);

  Future<void> _updateVerificationStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'verificationStatus': newStatus});

      onStatusUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} verification status updated to $newStatus'),
          backgroundColor: Color(0xFF00C851),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      print('Successfully updated ${user.name} status to $newStatus');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update verification status'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      print('Error updating verification status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1A0033),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Color(0xFFDA70D6), width: 2),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
              ),
            ),
            child: user.profileImageURL != null
                ? ClipOval(
              child: Image.network(
                user.profileImageURL!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, color: Colors.white, size: 20),
              ),
            )
                : Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Color(0xFFDA70D6), Color(0xFF8A2BE2)],
                  ).createShader(bounds),
                  child: Text(
                    'Update Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  user.name,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select verification status:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildCurrentStatus(user.verificationStatus),
          ],
        ),
      ),
      actions: <Widget>[
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDialogButton(
                    'Pending',
                    Color(0xFFFF8800),
                    Icons.pending,
                        () {
                      _updateVerificationStatus(context, 'pending');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildDialogButton(
                    'Verified',
                    Color(0xFF00C851),
                    Icons.verified,
                        () {
                      _updateVerificationStatus(context, 'verified');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Add the unverified button as a full-width button
            Container(
              width: double.infinity,
              child: _buildDialogButton(
                'Unverified',
                Color(0xFFFF6B6B),
                Icons.cancel,
                    () {
                  _updateVerificationStatus(context, 'unverified');
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildCurrentStatus(String currentStatus) {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(12),
  //       gradient: LinearGradient(
  //         colors: [
  //           Colors.white.withOpacity(0.1),
  //           Colors.white.withOpacity(0.05),
  //         ],
  //       ),
  //       border: Border.all(color: Colors.white24),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           currentStatus == 'verified' ? Icons.verified : Icons.pending,
  //           color: currentStatus == 'verified' ? Color(0xFF00C851) : Color(0xFFFF8800),
  //           size: 24,
  //         ),
  //         SizedBox(width: 12),
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Current Status',
  //               style: TextStyle(
  //                 color: Colors.white70,
  //                 fontSize: 12,
  //               ),
  //             ),
  //             Text(
  //               currentStatus.toUpperCase(),
  //               style: TextStyle(
  //                 color: currentStatus == 'verified' ? Color(0xFF00C851) : Color(0xFFFF8800),
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildCurrentStatus(String currentStatus) {
    Color statusColor;
    IconData statusIcon;

    switch (currentStatus) {
      case 'verified':
        statusColor = Color(0xFF00C851);
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = Color(0xFFFF8800);
        statusIcon = Icons.pending;
        break;
      case 'unverified':
        statusColor = Color(0xFFFF6B6B);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Color(0xFF6C757D);
        statusIcon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                currentStatus.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
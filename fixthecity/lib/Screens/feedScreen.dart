import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class EnhancedComplaintFeedScreen extends StatefulWidget {
  const EnhancedComplaintFeedScreen({super.key});

  @override
  State<EnhancedComplaintFeedScreen> createState() => _EnhancedComplaintFeedScreenState();
}

enum SortOption { latest, upvoted, nearby }

class _EnhancedComplaintFeedScreenState extends State<EnhancedComplaintFeedScreen>
    with TickerProviderStateMixin {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  SortOption _selectedSort = SortOption.latest;
  bool _isLoading = false;
  bool _showSearch = false;
  String _searchQuery = '';
  String? _selectedCategory;
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  bool _isLoadingLocation = false;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;

  final List<String> _categories = [
    'All',
    'Infrastructure',
    'Safety',
    'Environment',
    'Transportation',
    'Health',
    'Education',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All';

    // Initialize animation controllers with safe bounds
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animations safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _headerAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _fabAnimationController.forward();
          }
        });
      }
    });

    // Initialize location
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showTopNotification(
          'Location services are disabled. Please enable them in settings.',
          isWarning: true,
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showTopNotification(
            'Location permissions are denied. Nearby feature won\'t work.',
            isWarning: true,
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showTopNotification(
          'Location permissions are permanently denied. Please enable them in app settings.',
          isError: true,
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _locationPermissionGranted = true;
        _isLoadingLocation = false;
      });

      _showTopNotification(
        'Location updated successfully!',
        isSuccess: true,
      );

    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showTopNotification(
        'Failed to get location: $e',
        isError: true,
      );
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Method to show stunning top notifications
  void _showTopNotification(String message, {bool isSuccess = false, bool isError = false, bool isWarning = false, bool isInfo = false}) {
    if (!mounted) return;

    Widget notification;

    if (isError) {
      notification = CustomSnackBar.error(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    } else if (isWarning) {
      notification = CustomSnackBar.info(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    } else if (isInfo) {
      notification = CustomSnackBar.info(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      // Success notification
      notification = CustomSnackBar.success(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.green.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    }

    showTopSnackBar(
      Overlay.of(context),
      notification,
      animationDuration: const Duration(milliseconds: 1000),
      reverseAnimationDuration: const Duration(milliseconds: 600),
      displayDuration: const Duration(seconds: 4),
      dismissType: DismissType.onTap,
    );
  }

  List<String> _parseUpvotes(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    if (raw is String) {
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  Future<void> toggleUpvote(String docId, List<String> currentUpvotes) async {
    final docRef = FirebaseFirestore.instance.collection('complaints').doc(docId);

    try {
      if (currentUpvotes.contains(userId)) {
        await docRef.update({
          'upvotes': FieldValue.arrayRemove([userId])
        });
      } else {
        await docRef.update({
          'upvotes': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      _showTopNotification(
        'Error updating vote: $e',
        isError: true,
      );
    }
  }

  Future<int> _fetchCommentCount(String complaintId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('comments')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _refreshComplaints() async {
    try {
      setState(() => _isLoading = true);

      // Add a minimum delay for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      // The StreamBuilder will automatically update with new data

    } catch (e) {
      _showTopNotification(
        'Error refreshing: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Stream<List<QueryDocumentSnapshot>> _getSortedStream() {
    Query query = FirebaseFirestore.instance
        .collection('complaints')
        .where('status', whereNotIn: ['Withdrawn']);

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs;

      // Apply search filter
      List<QueryDocumentSnapshot> filteredDocs = docs;
      if (_searchQuery.isNotEmpty) {
        filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final description = (data['description'] ?? data['description'] ?? '').toString().toLowerCase();
          final address = (data['address'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? '').toString().toLowerCase();
          final department = (data['department'] ?? '').toString().toLowerCase();
          final title = (data['title'] ?? '').toString().toLowerCase();

          return description.contains(_searchQuery.toLowerCase()) ||
              address.contains(_searchQuery.toLowerCase()) ||
              category.contains(_searchQuery.toLowerCase()) ||
              department.contains(_searchQuery.toLowerCase()) ||
              title.contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Apply sorting
      if (_selectedSort == SortOption.upvoted) {
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aVotes = _parseUpvotes(aData['upvotes']).length;
          final bVotes = _parseUpvotes(bData['upvotes']).length;
          return bVotes.compareTo(aVotes);
        });
      } else if (_selectedSort == SortOption.nearby) {
        // Sort by distance if location is available
        if (_currentPosition != null) {
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            // Get coordinates from complaints
            final aLat = aData['latitude'] as double?;
            final aLon = aData['longitude'] as double?;
            final bLat = bData['latitude'] as double?;
            final bLon = bData['longitude'] as double?;

            // If coordinates are missing, put them at the end
            if (aLat == null || aLon == null) return 1;
            if (bLat == null || bLon == null) return -1;

            // Calculate distances
            final aDistance = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              aLat,
              aLon,
            );
            final bDistance = _calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              bLat,
              bLon,
            );

            return aDistance.compareTo(bDistance);
          });
        } else {
          // If no location, sort by latest
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;
            return (bTime ?? Timestamp(0, 0)).compareTo(aTime ?? Timestamp(0, 0));
          });
        }
      } else {
        // Latest sorting
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp'] as Timestamp?;
          final bTime = bData['timestamp'] as Timestamp?;
          return (bTime ?? Timestamp(0, 0)).compareTo(aTime ?? Timestamp(0, 0));
        });
      }

      return filteredDocs;
    });
  }

  Widget _buildEnhancedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -30 * (1 - _headerAnimationController.value)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: const Icon(Icons.explore, color: Colors.blue, size: 24),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Community Feed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchController.clear();
                              _searchQuery = '';
                            }
                          });
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _showSearch ? Icons.close : Icons.search,
                            key: ValueKey(_showSearch),
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButton<SortOption>(
                          value: _selectedSort,
                          onChanged: (newVal) {
                            if (newVal != null) {
                              // Check if nearby is selected but location is not available
                              if (newVal == SortOption.nearby && !_locationPermissionGranted) {
                                _showTopNotification(
                                  'Getting your location for nearby complaints...',
                                  isInfo: true,
                                );
                                _getCurrentLocation();
                              }
                              setState(() => _selectedSort = newVal);
                            }
                          },
                          underline: const SizedBox(),
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedSort == SortOption.nearby && _isLoadingLocation)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                )
                              else if (_selectedSort == SortOption.nearby && _locationPermissionGranted)
                                Icon(Icons.location_on, color: Colors.green.shade600, size: 14)
                              else if (_selectedSort == SortOption.nearby)
                                  Icon(Icons.location_off, color: Colors.red.shade600, size: 14),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 18),
                            ],
                          ),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(
                              value: SortOption.latest,
                              child: Text("Latest", style: TextStyle(color: Colors.blue, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: SortOption.upvoted,
                              child: Text("Popular", style: TextStyle(color: Colors.blue, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: SortOption.nearby,
                              child: Text("Nearby", style: TextStyle(color: Colors.blue, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showSearch ? 60 : 0,
                  child: _showSearch ?
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search complaints...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ) : const SizedBox.shrink(),
                ),

                // Category filter
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          label: Text(category),
                          selectedColor: Colors.blue.withOpacity(0.2),
                          checkmarkColor: Colors.blue,
                          backgroundColor: Colors.grey[100],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedCard(QueryDocumentSnapshot complaint, int index) {
    final data = complaint.data() as Map<String, dynamic>;
    final upvotes = _parseUpvotes(data['upvotes']);
    final hasUpvoted = upvotes.contains(userId);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Icon(Icons.person, color: Colors.blue[700]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['authorName'] ?? 'Anonymous User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(data['timestamp']),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(data['status']),
                        ],
                      ),
                    ),

                    // Title Section (if exists)
                    if (data['title'] != null && data['title'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          data['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                    // Image Section
                    if (data['images'] != null &&
                        data['images'] is List &&
                        (data['images'] as List).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () => _showImageViewer(data['images']),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: data['images'][0],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location with icon and distance
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red[400], size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['address'] ?? 'No address provided',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Show distance if nearby sorting and location available
                              if (_selectedSort == SortOption.nearby &&
                                  _currentPosition != null &&
                                  data['latitude'] != null &&
                                  data['longitude'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.near_me, color: Colors.blue[700], size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDistance(_calculateDistance(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                          data['latitude'],
                                          data['longitude'],
                                        )),
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Enhanced Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              // Category chip
                              if (data['category'] != null && data['category'].toString().isNotEmpty)
                                _buildChip(
                                  data['category'],
                                  Colors.blue,
                                  Icons.category,
                                ),
                              // Department chip (new field)
                              if (data['department'] != null && data['department'].toString().isNotEmpty)
                                _buildChip(
                                  data['department'],
                                  Colors.purple,
                                  Icons.business,
                                ),
                              // Severity chip (new field)
                              if (data['severity'] != null)
                                _buildSeverityChip(data['severity']),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Description
                          Text(
                            data['description'] ?? data['complaintDetails'] ?? '',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Estimated Resolution Time (new field)
                          if (data['estimatedResolutionTime'] != null && data['estimatedResolutionTime'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, color: Colors.orange[700], size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Est. Resolution: ${data['estimatedResolutionTime']}',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Engagement Bar
                          Row(
                            children: [
                              // Upvote Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () => toggleUpvote(complaint.id, upvotes),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasUpvoted
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: hasUpvoted ? Colors.green : Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasUpvoted
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_outlined,
                                          color: hasUpvoted
                                              ? Colors.green
                                              : Colors.grey[600],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${upvotes.length}',
                                          style: TextStyle(
                                            color: hasUpvoted
                                                ? Colors.green
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Comments Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () => _showCommentsSheet(complaint.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(color: Colors.blue, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.comment_outlined,
                                            color: Colors.blue, size: 18),
                                        const SizedBox(width: 6),
                                        FutureBuilder<int>(
                                          future: _fetchCommentCount(complaint.id),
                                          builder: (context, snapshot) {
                                            final count = snapshot.data ?? 0;
                                            return Text(
                                              '$count',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Share Button
                              IconButton(
                                onPressed: () => _shareComplaint(data),
                                icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeverityChip(dynamic severityData) {
    MaterialColor color;
    IconData icon;
    String label;

    // Handle both string and int severity values
    if (severityData is String) {
      switch (severityData.toLowerCase()) {
        case 'low':
          color = Colors.green;
          icon = Icons.trending_down;
          label = 'Low';
          break;
        case 'medium':
          color = Colors.orange;
          icon = Icons.trending_flat;
          label = 'Medium';
          break;
        case 'high':
          color = Colors.red;
          icon = Icons.trending_up;
          label = 'High';
          break;
        default:
          color = Colors.grey;
          icon = Icons.help_outline;
          label = severityData;
      }
    } else if (severityData is int) {
      if (severityData <= 2) {
        color = Colors.green;
        icon = Icons.trending_down;
        label = 'Low';
      } else if (severityData == 3) {
        color = Colors.orange;
        icon = Icons.trending_flat;
        label = 'Medium';
      } else {
        color = Colors.red;
        icon = Icons.trending_up;
        label = 'High';
      }
    } else {
      color = Colors.grey;
      icon = Icons.help_outline;
      label = 'Unknown';
    }

    return _buildChip(label, color, icon);
  }

  void _showImageViewer(List images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(String complaintId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        complaintId: complaintId,
      ),
    );
  }

  void _shareComplaint(Map<String, dynamic> data) {
    final text = '''
🚨 Community Complaint Alert!

${data['title'] != null ? '📋 Title: ${data['title']}\n' : ''}
📍 Location: ${data['address'] ?? 'Unknown'}
🏷️ Category: ${data['category'] ?? 'General'}
${data['department'] != null ? '🏢 Department: ${data['department']}\n' : ''}
📝 Issue: ${data['description'] ?? data['complaintDetails'] ?? 'No details'}
⚡ Status: ${data['status'] ?? 'New'}
${data['estimatedResolutionTime'] != null ? '⏰ Est. Resolution: ${data['estimatedResolutionTime']}\n' : ''}

Help make our community better! 
#CommunityFeedback #CivicEngagement
    ''';

    Share.share(text, subject: 'Community Complaint Report');
  }

  Widget _buildChip(String label, MaterialColor color, IconData icon) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    IconData icon;

    switch (status?.toLowerCase().trim()) {
      case String s when s.contains('resolved'):
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case String s when s.contains('in progress'):
        color = Colors.orange;
        icon = Icons.work;
        break;
      case String s when s.contains('review'):
        color = Colors.blue;
        icon = Icons.visibility;
        break;
      default:
        color = Colors.grey;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            status ?? 'New',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (value * 0.5),
                child: Opacity(
                  opacity: value,
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No complaints found for "$_searchQuery"'
                : 'No complaints found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedHeader(),
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshComplaints,
                color: Colors.blue,
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                child: _isLoading
                    ? _buildLoadingShimmer()
                    : StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: _getSortedStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                      return _buildLoadingShimmer();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading complaints',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _refreshIndicatorKey.currentState?.show();
                              },
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final complaints = snapshot.data!;

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        return _buildEnhancedCard(complaints[index], index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: AnimatedBuilder(
      //   animation: _fabAnimationController,
      //   builder: (context, child) {
      //     return Transform.scale(
      //       scale: _fabAnimationController.value,
      //       child: FloatingActionButton(
      //         onPressed: () {
      //           // Navigate to create complaint screen
      //         },
      //         backgroundColor: Colors.blueAccent,
      //         child: const Icon(Icons.add, color: Colors.white),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

// Enhanced Comments Bottom Sheet
class CommentsBottomSheet extends StatefulWidget {
  final String complaintId;

  const CommentsBottomSheet({
    super.key,
    required this.complaintId,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isSubmitting = false;

  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Method to show stunning top notifications
  void _showTopNotification(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;

    Widget notification;

    if (isError) {
      notification = CustomSnackBar.error(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      notification = CustomSnackBar.success(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.green.shade600,
        borderRadius: BorderRadius.circular(12),
      );
    }

    showTopSnackBar(
      Overlay.of(context),
      notification,
      animationDuration: const Duration(milliseconds: 1000),
      reverseAnimationDuration: const Duration(milliseconds: 600),
      displayDuration: const Duration(seconds: 4),
      dismissType: DismissType.onTap,
    );
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();

      _showTopNotification(
        'Comment added successfully!',
        isSuccess: true,
      );
    } catch (e) {
      _showTopNotification(
        'Error adding comment: $e',
        isError: true,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _formatCommentTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 500 * (1 - _slideController.value)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Comments list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('complaints')
                        .doc(widget.complaintId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data?.docs ?? [];

                      if (comments.isEmpty) {
                        return const Center(
                          child: Text(
                            'No comments yet.\nBe the first to comment!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index].data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: Icon(Icons.person, color: Colors.blue[700]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment['userName'] ?? 'Anonymous',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatCommentTime(comment['timestamp']),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['comment'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Comment input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isSubmitting ? Colors.grey : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isSubmitting ? null : _submitComment,
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
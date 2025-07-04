import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const MapPage({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.title,
  }) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late MapController _mapController;
  double _currentZoom = 15.0;
  String? _address;
  bool _isLoading = false;
  LatLng? _currentUserLocation;

  // Animation controllers
  late AnimationController _markerAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _markerScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _markerAnimationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    try {
      await _updateAddress(LatLng(widget.latitude, widget.longitude));
      await _getCurrentUserLocation();
    } catch (e) {
      _showErrorSnackBar('Error loading map: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Silently handle location errors
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _updateAddress(LatLng point) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
        localeIdentifier: 'en',
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _address = _formatAddress(placemarks.first);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error getting address: ${e.toString()}');
    }
  }

  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          _buildAddressDisplay(),
          _buildZoomControl(),
          if (_isLoading) _buildLoadingIndicator(),
          _buildFloatingActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Complaint Location',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(widget.latitude, widget.longitude),
        zoom: _currentZoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            setState(() => _currentZoom = position.zoom ?? _currentZoom);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        _buildMarkerLayer(),
      ],
    );
  }

  Widget _buildMarkerLayer() {
    List<Marker> markers = [];

    // Complaint location marker
    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(widget.latitude, widget.longitude),
        builder: (ctx) => AnimatedBuilder(
          animation: _markerScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _markerScaleAnimation.value,
              child: Container(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Complaint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    // User location marker (if available)
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          width: 60.0,
          height: 60.0,
          point: _currentUserLocation!,
          builder: (ctx) => Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildAddressDisplay() {
    return _address != null
        ? Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Complaint Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _address!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${widget.latitude.toStringAsFixed(6)}, Lng: ${widget.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  Widget _buildZoomControl() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _changeZoom(1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ),
            Container(
              width: 48,
              height: 1,
              color: Colors.grey.shade200,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _changeZoom(-1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeZoom(double delta) {
    final newZoom = (_currentZoom + delta).clamp(5.0, 18.0);
    _mapController.move(_mapController.center, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading location...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return AnimatedBuilder(
      animation: _fabSlideAnimation,
      builder: (context, child) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16 + _fabSlideAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButton(
                onPressed: _centerOnComplaint,
                backgroundColor: Colors.deepPurple,
                heroTag: 'center_button',
                child: const Icon(Icons.center_focus_strong, color: Colors.white),
              ),
              if (_currentUserLocation != null)
                FloatingActionButton(
                  onPressed: _showRoute,
                  backgroundColor: Colors.green.shade600,
                  heroTag: 'route_button',
                  child: const Icon(Icons.directions, color: Colors.white),
                ),
              FloatingActionButton.extended(
                onPressed: _openInExternalMap,
                backgroundColor: Colors.blue.shade600,
                heroTag: 'external_button',
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text(
                  'Open External',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _centerOnComplaint() {
    _mapController.move(LatLng(widget.latitude, widget.longitude), 16.0);
    setState(() => _currentZoom = 16.0);
  }

  void _showRoute() {
    if (_currentUserLocation != null) {
      // Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        widget.latitude,
        widget.longitude,
      );

      String distance = distanceInMeters > 1000
          ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km'
          : '${distanceInMeters.toStringAsFixed(0)} m';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Route Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance: $distance'),
              const SizedBox(height: 8),
              const Text('Open in external map app for detailed directions.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openInExternalMap();
              },
              child: const Text('Open Map'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openInExternalMap() async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
    final String appleMapsUrl =
        'https://maps.apple.com/?q=${widget.latitude},${widget.longitude}';

    try {
      // Try Google Maps first
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('No map application found');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening map: ${e.toString()}');
    }
  }
}
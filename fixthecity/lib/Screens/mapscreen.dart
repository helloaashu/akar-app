import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? _selectedLocation;
  String? _address;
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();
  bool _isLoading = false;
  double _currentZoom = 13.0;
  bool _isDragging = false;
  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _markerAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _debounceTimer?.cancel();
    _markerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    try {
      final position = await _determinePosition();
      _handleTap(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      _handleTap(LatLng(27.7172, 85.3240)); // Default to Kathmandu
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          _buildSearchBar(),
          _buildAddressDisplay(),
          _buildZoomControl(),
          _buildCenterIndicator(),
          if (_isLoading) _buildLoadingIndicator(),
          _buildFloatingActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Select Location',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _selectedLocation ?? LatLng(27.7172, 85.3240),
        zoom: _currentZoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (_, point) => _handleTap(point),
        onPositionChanged: _handlePositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        if (_selectedLocation != null) _buildMarkerLayer(),
      ],
    );
  }

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          width: 80.0,
          height: 80.0,
          point: _selectedLocation!,
          builder: (ctx) => GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: _handleMarkerDrag,
            onPanEnd: (_) => _onDragEnd(),
            child: AnimatedBuilder(
              animation: _markerScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isDragging ? 1.2 : _markerScaleAnimation.value,
                  child: Container(
                    width: 40,
                    height: 40,
                    // decoration: BoxDecoration(
                    //   color: Colors.red,
                    //   shape: BoxShape.circle,
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.red.withOpacity(0.3),
                    //       blurRadius: 10,
                    //       spreadRadius: 2,
                    //     ),
                    //   ],
                    // ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _handleMarkerDrag(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final newPosition = renderBox.globalToLocal(details.globalPosition);
    final newPoint = _mapController.pointToLatLng(CustomPoint(newPosition.dx, newPosition.dy));
    setState(() => _selectedLocation = newPoint);
  }

  void _onDragEnd() {
    setState(() => _isDragging = false);
    _debouncedUpdateAddress(_selectedLocation!);
  }

  void _debouncedUpdateAddress(LatLng point) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _updateAddress(point));
  }

  void _handlePositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _currentZoom = position.zoom ?? _currentZoom;
        _selectedLocation = position.center;
      });
      _debouncedUpdateAddress(position.center!);
    }
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TypeAheadField(
          textFieldConfiguration: TextFieldConfiguration(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Search for a location...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              suffixIcon: _addressController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                onPressed: () {
                  _addressController.clear();
                  setState(() {});
                },
              )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          suggestionsCallback: _fetchAddressSuggestions,
          itemBuilder: (context, suggestion) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: ListTile(
                leading: Icon(Icons.location_on, color: Colors.grey.shade600),
                title: Text(
                  suggestion['display_name'],
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
              ),
            );
          },
          onSuggestionSelected: (suggestion) {
            _addressController.text = suggestion['display_name'];
            _handleTap(LatLng(
              double.parse(suggestion['lat']),
              double.parse(suggestion['lon']),
            ));
          },
          suggestionsBoxDecoration: SuggestionsBoxDecoration(
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            color: Colors.white,
          ),
          hideOnEmpty: true,
          hideOnError: true,
        ),
      ),
    );
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _address!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
      top: 100,
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

  Widget _buildCenterIndicator() {
    return Center(
      child: Container(
        width: 2,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
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
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.blue.shade600,
                heroTag: 'location_button',
                child: const Icon(Icons.my_location, color: Colors.white),
              ),

              FloatingActionButton.extended(
                onPressed: _confirmLocation,
                backgroundColor: Colors.green.shade600,
                heroTag: 'confirm_button',
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Confirm',
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

  String formatAddress(Placemark place) {
    if (place.country?.toLowerCase() == 'nepal') {
      return [
        place.street,
        place.subLocality,
        place.locality,
        '${place.subAdministrativeArea} Municipality',
        '${place.administrativeArea} ',
        place.postalCode,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    } else {
      return [
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }
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
          _address = formatAddress(placemarks.first);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error getting address: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(String query) async {
    if (query.length <= 2) return [];

    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      _handleTap(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _showErrorSnackBar('Unable to get current location: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleTap(LatLng point) async {
    setState(() {
      _selectedLocation = point;
      _isLoading = true;
    });

    _markerAnimationController.forward();
    await _updateAddress(point);

    setState(() => _isLoading = false);
    _mapController.move(point, _currentZoom);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _buildConfirmationDialog(),
      );
    }
  }

  Widget _buildConfirmationDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Confirm Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Is this the correct location?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // Location details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_address != null) ...[
                    _buildDetailRow(
                      Icons.location_on,
                      'Address',
                      _address!,
                      Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDetailRow(
                    Icons.explore,
                    'Latitude',
                    _selectedLocation!.latitude.toStringAsFixed(6),
                    Colors.green.shade600,
                  ),

                  const SizedBox(height: 12),

                  _buildDetailRow(
                    Icons.explore,
                    'Longitude',
                    _selectedLocation!.longitude.toStringAsFixed(6),
                    Colors.orange.shade600,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, {
                        'location': _selectedLocation,
                        'address': _address,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'ors_service.dart';
import 'profile_page.dart';
import 'friend_management_page.dart';
import 'firestore_service.dart';

class Friend {
  final String id;
  final String name;
  final String email;
  final LatLng? location;

  Friend({required this.id, required this.name, required this.email, this.location});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  final ValueNotifier<LatLng?> _currentLocationNotifier = ValueNotifier(null);

  LatLng? _mapCenter;
  Timer? _locationUpdateTimer;
  Duration? _tripDuration;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _currentLocationNotifier.dispose();
    super.dispose();
  }

  void _initLocationTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      final initialPos = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      _currentLocationNotifier.value = initialPos;
      setState(() {
        _mapCenter = initialPos;
      });
      _firestoreService.updateUserLocation(initialPos);
    } catch (e) {
      print('❌ Lỗi lấy vị trí lần đầu: $e');
    }

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;

      try {
        final position = await Geolocator.getCurrentPosition();
        final newPos = LatLng(position.latitude, position.longitude);

        if (_currentLocationNotifier.value != null) {
          final double distance = const Distance().as(
            LengthUnit.Meter,
            _currentLocationNotifier.value!,
            newPos,
          );
          if (distance > 300) {
            print('📛 Vị trí nhảy quá xa: ${distance.round()}m. Bỏ qua cập nhật.');
            return;
          }
        }

        if (!mounted) return;
        _currentLocationNotifier.value = newPos;
        _firestoreService.updateUserLocation(newPos);
      } catch (e) {
        print('❌ Lỗi lấy vị trí định kỳ: $e');
      }
    });
  }

  void _zoomToMyLocation() {
    if (_currentLocationNotifier.value != null) {
      _mapController.move(_currentLocationNotifier.value!, 16.0);
    }
  }

  Future<void> _showPathSelectionDialog() async {
    if (_currentLocationNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có vị trí hiện tại để tìm đường!')));
      return;
    }

    final friendsWithLocation = _friends.where((f) => f.location != null).toList();

    if (friendsWithLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có bạn bè nào online.')));
      return;
    }

    final selectedFriend = await showDialog<Friend>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm đường đến'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: friendsWithLocation.length,
            itemBuilder: (context, index) {
              final friend = friendsWithLocation[index];
              return ListTile(
                title: Text(friend.name),
                onTap: () => Navigator.of(context).pop(friend),
              );
            },
          ),
        ),
      ),
    );

    if (selectedFriend == null) return;

    final friendPosition = selectedFriend.location!;
    setState(() {
      _isLoadingRoute = true;
      _routePoints.clear();
    });

    try {
      final routeInfo = await getRouteORS(_currentLocationNotifier.value!, friendPosition);
      setState(() {
        _routePoints = routeInfo.points;
        _tripDuration = routeInfo.duration;
      });

      _mapController.fitCamera(
        CameraFit.coordinates(coordinates: _routePoints, padding: const EdgeInsets.all(50.0)),
      );

      if (_tripDuration != null && mounted) {
        final minutes = _tripDuration!.inMinutes;
        final seconds = _tripDuration!.inSeconds % 60;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thời gian di chuyển dự kiến: $minutes phút $seconds giây.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tìm đường: $e')));
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ bạn bè'),
        actions: [
          IconButton(icon: const Icon(Icons.alt_route), onPressed: _showPathSelectionDialog),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Quản lý bạn bè',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsManagementPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Text(
                '📍 Đang theo dõi vị trí bạn bè thời gian thực',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getFriendsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildMap([]);

                  final friendIds = snapshot.data!.docs.map((doc) => doc.id).toList();

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: _firestoreService.getUsersByIds(friendIds),
                    builder: (context, userSnapshots) {
                      if (!userSnapshots.hasData) return const Center(child: CircularProgressIndicator());

                      _friends = userSnapshots.data!.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final locationData = data['location'] as GeoPoint?;
                        return Friend(
                          id: doc.id,
                          name: data['name'] ?? 'N/A',
                          email: data['email'] ?? 'N/A',
                          location: locationData != null
                              ? LatLng(locationData.latitude, locationData.longitude)
                              : null,
                        );
                      }).toList();

                      return _buildMap(_friends);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<Friend> friends) {
    if (_mapCenter == null) return const Center(child: Text('⏳ Đang lấy vị trí...'));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter!,
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiMnRteTI2IiwiYSI6ImNtOXkzNnBmczFjc3MyaXB5bWhxNzA5aXMifQ.NGsfTuxwfT6P5K2EVwucTQ',
              userAgentPackageName: 'com.example.tracking',
            ),
            PolylineLayer(
              polylines: [Polyline(points: _routePoints, strokeWidth: 4, color: Colors.green)],
            ),
            ValueListenableBuilder<LatLng?>(
              valueListenable: _currentLocationNotifier,
              builder: (context, currentLocation, child) {
                if (currentLocation == null) return const SizedBox.shrink();
                return MarkerLayer(
                  markers: [
                    ...friends.where((f) => f.location != null).map(
                          (friend) => Marker(
                        point: friend.location!,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            const Icon(Icons.location_pin, color: Colors.red, size: 35),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Text(
                                friend.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Marker(
                      point: currentLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _zoomToMyLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
        if (_isLoadingRoute)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

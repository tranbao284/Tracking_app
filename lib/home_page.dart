import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'ors_service.dart';
import 'profile_page.dart';
import 'friend_management_page.dart';
import 'firestore_service.dart'; //  Quan trọng: Thêm import này

//  Tạo một class để chứa thông tin bạn bè cho dễ quản lý
class Friend {
  final String id;
  final String displayName;
  final String email;
  final LatLng? location;

  Friend({
    required this.id,
    required this.displayName,
    required this.email,
    this.location,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService(); //  Khởi tạo service

  LatLng? _currentLocation;
  Timer? _locationUpdateTimer;
  Duration? _tripDuration;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  //  Danh sách bạn bè sẽ được cập nhật từ Stream
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel(); // Hủy timer khi widget bị xóa
    super.dispose();
  }

  void _initLocationTracking() async {
    // ... (Phần code xin quyền giữ nguyên)
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    // Lấy vị trí lần đầu
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      final initialPos = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = initialPos;
        });
        // Cập nhật vị trí lên Firebase
        _firestoreService.updateUserLocation(initialPos);
      }
    } catch (e) {
      print(' Lỗi lấy vị trí lần đầu: $e');
    }

    //Cập nhật vị trí mỗi 10 giây và lưu lên Firebase
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        final newPos = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _currentLocation = newPos;
          });
          // Cập nhật vị trí lên Firebase
          _firestoreService.updateUserLocation(newPos);
        }
      } catch (e) {
        print(' Lỗi lấy vị trí định kỳ: $e');
      }
    });
  }

  Future<void> _showPathSelectionDialog() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có vị trí hiện tại để tìm đường!')),
      );
      return;
    }

    //  Lấy danh sách bạn bè có vị trí để chọn
    final friendsWithLocation = _friends.where((f) => f.location != null).toList();

    if (friendsWithLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có bạn bè nào online.')),
      );
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
                title: Text(friend.displayName),
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
      final routeInfo = await getRouteORS(_currentLocation!, friendPosition);
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

  void _zoomToMyLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsManagementPage())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getFriendsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Vẫn hiển thị bản đồ ngay cả khi không có bạn bè
            return _buildMap([]);
          }

          final friendIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _firestoreService.getUsersByIds(friendIds),
            builder: (context, userSnapshots) {
              if (!userSnapshots.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              //  Cập nhật danh sách bạn bè từ dữ liệu mới nhất
              _friends = userSnapshots.data!.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final locationData = data['location'] as GeoPoint?;
                return Friend(
                  id: doc.id,
                  displayName: data['displayName'] ?? 'N/A',
                  email: data['email'] ?? 'N/A',
                  location: locationData != null ? LatLng(locationData.latitude, locationData.longitude) : null,
                );
              }).toList();

              //  Xây dựng bản đồ với danh sách bạn bè đã được cập nhật
              return _buildMap(_friends);
            },
          );
        },
      ),
    );
  }

  //  Tách riêng widget bản đồ để dễ quản lý
  Widget _buildMap(List<Friend> friends) {
    if (_currentLocation == null) {
      return const Center(child: Text('⏳ Đang lấy vị trí...'));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiMnRteTI2IiwiYSI6ImNtOXkzNnBmczFjc3MyaXB5bWhxNzA5aXMifQ.NGsfTuxwfT6P5K2EVwucTQ',
              userAgentPackageName: 'com.example.tracking',
            ),
            PolylineLayer(
              polylines: [Polyline(points: _routePoints, strokeWidth: 4, color: Colors.green)],
            ),
            MarkerLayer(
              markers: [
                //  Vẽ marker cho bạn bè
                ...friends.where((f) => f.location != null).map(
                      (friend) => Marker(
                    point: friend.location!,
                    width: 80,
                    height: 80,
                    child: Tooltip(
                      message: friend.displayName,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 35),
                    ),
                  ),
                ),
                // Marker cho vị trí của chính mình
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                ),
              ],
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'friend_list_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  final Map<String, LatLng> friendLocations = {
    'Ngoc': LatLng(21.030, 105.800),
    'Huy': LatLng(21.035, 105.805),
  };

  void _goToFriend(String name) {
    final location = friendLocations[name];
    if (location != null) {
      _mapController.move(location, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC1E3),
        title: Row(
          children: [
            const Icon(Icons.map, color: Color(0xFFB5F8FE)),
            const SizedBox(width: 8),
            const Text('Bản đồ bạn bè 🗺️', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.people_alt, color: Color(0xFFB5F8FE)),
          onPressed: () async {
            final selected = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (context) => const FriendListScreen()),
            );
            if (selected != null) _goToFriend(selected);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFB5F8FE)),
            onPressed: () {
              // Nếu muốn điều hướng sang ProfilePage mới đã sửa theme:
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
            },
          ),
        ],
        elevation: 0,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(21.028511, 105.804817),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiMnRteTI2IiwiYSI6ImNtOXkzNnBmczFjc3MyaXB5bWhxNzA5aXMifQ.NGsfTuxwfT6P5K2EVwucTQ',
            userAgentPackageName: 'com.example.tracking',
          ),
          MarkerLayer(
            markers: friendLocations.entries.map((entry) {
              return Marker(
                width: 40,
                height: 40,
                point: entry.value,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 30,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 
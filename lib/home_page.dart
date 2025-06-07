import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'friend_list_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      appBar: AppBar(
        title: const Text('Bản đồ bạn bè'),
        leading: IconButton(
          icon: const Icon(Icons.people_alt),
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
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
                point: entry.value,
                width: 40,
                height: 40,
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

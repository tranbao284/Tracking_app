import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
class RouteInfo {
  final List<LatLng> points;
  final Duration duration; // Duration để lưu trữ thời gian

  RouteInfo({required this.points, required this.duration});
}
Future<RouteInfo> getRouteORS(LatLng start, LatLng end) async {
  const apiKey = '5b3ce3597851110001cf6248960e0622845e496f9d124ecd89de2515'; //
  final url = Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson');

  final body = jsonEncode({
    "coordinates": [
      [start.longitude, start.latitude],
      [end.longitude, end.latitude]
    ]
  });

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'][0];

      // Lấy danh sách tọa độ như cũ
      final coords = features['geometry']['coordinates'] as List;
      final points = coords.map((c) => LatLng(c[1], c[0])).toList();

      // Lấy thời gian di chuyển (tính bằng giây)
      final durationInSeconds = features['properties']['summary']['duration'] as double;
      final duration = Duration(seconds: durationInSeconds.round());

      // Trả về đối tượng RouteInfo chứa cả hai thông tin
      return RouteInfo(points: points, duration: duration);
    } else {
      throw Exception('❌ Lỗi từ ORS: ${response.statusCode} | ${response.body}');
    }
  } catch (e) {
    print('❗ Lỗi exception khi gọi ORS: $e');
    rethrow;
  }
}



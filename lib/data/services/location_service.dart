import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position?> currentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<String?> cityFrom(Position p) async {
    final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
    if (placemarks.isEmpty) return null;
    final pm = placemarks.first;
    // Prefer locality/subLocality; fall back to administrativeArea
    final parts = [pm.subLocality, pm.locality, pm.administrativeArea]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

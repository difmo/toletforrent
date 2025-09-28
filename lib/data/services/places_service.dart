import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Put your Maps API key here (or inject via constructor/env).
const _kGoogleApiKey = 'AIzaSyBZCSRr8pkuBKSE6eDvYBX4UYzgxJY0_HM';

class PlaceSuggestion {
  final String description;
  final String primary;
  final String? secondary;
  final Position?
      position; // may be null for autocomplete until details fetched

  PlaceSuggestion({
    required this.description,
    required this.primary,
    this.secondary,
    this.position,
  });
}

class PlacesService {
  final String apiKey;
  PlacesService({String? apiKey}) : apiKey = apiKey ?? _kGoogleApiKey;

  bool get _enabled => apiKey.isNotEmpty && apiKey != '';

  /// Nearby localities (up to [maxResults]) around [pos] within [radiusMeters].
  Future<List<PlaceSuggestion>> nearbyLocalities(
    Position pos,
    int radiusMeters, {
    int maxResults = 10,
  }) async {
    if (!_enabled) {
      // Fallback: a few popular cities (no GPS awareness)
      return _fallbackCities().take(maxResults).toList();
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${pos.latitude},${pos.longitude}'
      '&radius=$radiusMeters'
      '&type=locality'
      '&key=$apiKey',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body);
    final results = (json['results'] as List? ?? []);
    return results.take(maxResults).map((r) {
      final name = (r['name'] ?? '').toString();
      final vicinity = (r['vicinity'] ?? '').toString();
      final lat = (r['geometry']?['location']?['lat'] as num?)?.toDouble();
      final lng = (r['geometry']?['location']?['lng'] as num?)?.toDouble();
      return PlaceSuggestion(
        description: vicinity.isNotEmpty ? '$name, $vicinity' : name,
        primary: name,
        secondary: vicinity.isNotEmpty ? vicinity : null,
        position: (lat != null && lng != null)
            ? Position(
                latitude: lat,
                longitude: lng,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              )
            : null,
      );
    }).toList();
  }

  /// Autocomplete localities, biased towards [bias] if provided.
  Future<List<PlaceSuggestion>> autocompleteLocalities(
    String query, {
    Position? bias,
  }) async {
    if (!_enabled) {
      // Fallback: filter the static list
      final all = _fallbackCities();
      final q = query.toLowerCase();
      return all.where((c) => c.description.toLowerCase().contains(q)).toList();
    }

    final components = 'country:in'; // limit to India (optional)
    final locationBias = bias == null
        ? ''
        : '&locationbias=point:${bias.latitude},${bias.longitude}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input'
      '=${Uri.encodeComponent(query)}'
      '&types=(cities)'
      '&components=$components'
      '$locationBias'
      '&key=$apiKey',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body);
    final preds = (json['predictions'] as List? ?? []);
    return preds.map((p) {
      final desc = (p['description'] ?? '').toString();
      final primary =
          (p['structured_formatting']?['main_text'] ?? '').toString();
      final secondary =
          (p['structured_formatting']?['secondary_text'])?.toString();
      return PlaceSuggestion(
        description: desc,
        primary: primary.isEmpty ? desc : primary,
        secondary: secondary,
        position: null, // could call place/details to fetch lat/lng if you need
      );
    }).toList();
  }

  List<PlaceSuggestion> _fallbackCities() => [
        'Mumbai, Maharashtra',
        'Delhi, NCR',
        'Bengaluru, Karnataka',
        'Hyderabad, Telangana',
        'Chennai, Tamil Nadu',
        'Pune, Maharashtra',
        'Kolkata, West Bengal',
        'Ahmedabad, Gujarat',
        'Jaipur, Rajasthan',
        'Surat, Gujarat',
      ]
          .map((c) => PlaceSuggestion(
              description: c, primary: c, secondary: null, position: null))
          .toList();
}

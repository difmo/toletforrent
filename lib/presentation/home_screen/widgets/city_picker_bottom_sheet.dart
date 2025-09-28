import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toletforrent/data/services/places_service.dart';
import '../../../core/app_export.dart';
import 'package:toletforrent/data/services/location_service.dart';

// Model for returning selection
class PlaceSelectionResult {
  final String displayName;
  final Position? position;
  PlaceSelectionResult(this.displayName, this.position);
}

class CityPickerBottomSheet extends StatefulWidget {
  final String? initialCity;
  final Position? initialPosition;
  final int radiusKm;

  const CityPickerBottomSheet({
    super.key,
    this.initialCity,
    this.initialPosition,
    this.radiusKm = 10,
  });

  @override
  State<CityPickerBottomSheet> createState() => _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState extends State<CityPickerBottomSheet> {
  final _searchCtrl = TextEditingController();
  final _places = PlacesService(); // wraps Google Places (or fallback)
  Timer? _debounce;

  bool _loadingNearby = true;
  List<PlaceSuggestion> _nearby = [];
  List<PlaceSuggestion> _search = [];

  Position? _pos; // working position

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPosition;
    _bootstrap();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingNearby = true);

    // ensure we have a position
    _pos ??= await LocationService.currentPosition();

    List<PlaceSuggestion> near = [];
    if (_pos != null) {
      near = await _places.nearbyLocalities(_pos!, widget.radiusKm * 1000,
          maxResults: 10);
    }

    if (!mounted) return;
    setState(() {
      _nearby = near;
      _loadingNearby = false;
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() => _search = []);
        return;
      }
      final pos = _pos ?? await LocationService.currentPosition();
      final res = await _places.autocompleteLocalities(q, bias: pos);
      if (!mounted) return;
      setState(() => _search = res.take(10).toList());
    });
  }

  void _select(PlaceSuggestion s) {
    final pos = s.position ??
        (_pos != null
            ? Position(
                latitude: _pos!.latitude,
                longitude: _pos!.longitude,
                timestamp: DateTime.now(),
                accuracy: _pos!.accuracy,
                altitude: _pos!.altitude,
                heading: _pos!.heading,
                speed: _pos!.speed,
                speedAccuracy: _pos!.speedAccuracy,
                altitudeAccuracy: _pos!.altitudeAccuracy,
                headingAccuracy: _pos!.headingAccuracy,
              )
            : null);
    Navigator.pop(context, PlaceSelectionResult(s.description, pos));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Grab handle
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Location',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search city or area',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          SizedBox(height: 1.h),

          // Nearby section
          if (_loadingNearby)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: _searchCtrl.text.isNotEmpty
                  ? _buildList(_search, title: 'Results')
                  : _buildList(_nearby, title: 'Nearby (within 10 km)'),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<PlaceSuggestion> items, {required String title}) {
    final theme = AppTheme.lightTheme;
    if (items.isEmpty) {
      return Center(
        child: Text('No places found', style: theme.textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: EdgeInsets.only(top: 1.h, bottom: 1.h),
            child: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          );
        }
        final s = items[i - 1];
        return ListTile(
          leading: Icon(Icons.location_on,
              color: AppTheme.lightTheme.colorScheme.primary),
          title: Text(s.primary),
          subtitle: s.secondary == null ? null : Text(s.secondary!),
          onTap: () => _select(s),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import 'package:toletforrent/data/services/location_service.dart';
import '../../../core/app_export.dart';
import 'location_header_widget.dart';

class LocationHeaderLive extends StatefulWidget {
  final String currentCity; 
  final int radiusKm;
  final VoidCallback? onChangeTap; 
  final ValueChanged<String>? onCityChanged; 
  final ValueChanged<Position?>? onPositionChanged; 

  const LocationHeaderLive({
    super.key,
    required this.currentCity,
    this.radiusKm = 10,
    this.onChangeTap,
    this.onCityChanged,
    this.onPositionChanged,
  });

  @override
  State<LocationHeaderLive> createState() => _LocationHeaderLiveState();
}

class _LocationHeaderLiveState extends State<LocationHeaderLive> {
  String? _city; // local, mutable
  Position? _pos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _city = widget.currentCity; // seed with parent value
    _load(); // auto-refresh from GPS
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final pos = await LocationService.currentPosition();
    String? city;
    if (pos != null) {
      city = await LocationService.cityFrom(pos);
    }

    if (!mounted) return;
    setState(() {
      _pos = pos;
      _city = city ?? _city ?? widget.currentCity;
      _loading = false;
    });

    // notify parent (optional)
    if (city != null) widget.onCityChanged?.call(city);
    widget.onPositionChanged?.call(pos);
  }

  @override
  Widget build(BuildContext context) {
    final label = _loading ? 'Getting location…' : (_city ?? 'Enable location');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationHeaderWidget(
          currentCity: label,
          onLocationTap: () {
            // refresh GPS city
            _load();
            // and still allow any extra parent action
            widget.onChangeTap?.call();
          },
        ),
        if (_pos != null)
          Padding(
            padding: EdgeInsets.only(left: 10.w, bottom: 1.h),
            child: Text(
              'Showing places within ${widget.radiusKm} km',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  // Expose if you want to read it from the stateful element
  Position? get position => _pos;
}

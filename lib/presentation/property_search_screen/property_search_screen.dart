import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/active_filters_widget.dart';
import './widgets/filter_section_widget.dart';
import './widgets/map_view_widget.dart';
import './widgets/search_header_widget.dart';
import './widgets/search_results_widget.dart';

class PropertySearchScreen extends StatefulWidget {
  const PropertySearchScreen({super.key});

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  String _searchQuery = '';
  RangeValues _priceRange = const RangeValues(1000, 50000);
  List<String> _selectedBHK = [];
  List<String> _selectedPropertyTypes = [];
  List<String> _selectedFurnishedStatus = [];
  bool _isGridView = false;
  bool _isMapView = false;
  String _sortBy = 'Relevance';
  int _resultCount = 0; // updated from stream builder

  // ---------- helpers ----------
  String _asString(Object? v, {String def = ''}) => v?.toString() ?? def;
  int _asInt(Object? v, {int def = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String)
      return int.tryParse(v.replaceAll(RegExp(r'[^\d\-]'), '')) ?? def;
    return def;
  }

  List<String> _asStringList(Object? v) => (v is List)
      ? v.where((e) => e != null).map((e) => e.toString()).toList()
      : const [];

  /// Build a Firestore query with index-friendly filters.
  /// Strategy:
  /// - Always filter by numeric `rent` range (requires orderBy('rent')).
  /// - If exactly one `type` / `bhk` / `furnished` selected, add equality (more than one → filter client-side).
  /// - Sorting: if user picked a price sort, keep orderBy('rent'); if "Newest First" try 'createdAt'.
  Query<Map<String, dynamic>> _buildQuery() {
    final col = FirebaseFirestore.instance.collection('properties');

    // Base with rent range
    Query<Map<String, dynamic>> q = col
        .where('rent', isGreaterThanOrEqualTo: _priceRange.start.round())
        .where('rent', isLessThanOrEqualTo: _priceRange.end.round())
        .orderBy('rent'); // needed for range

    // Add single-value equality filters (safe for indexes)
    if (_selectedPropertyTypes.length == 1) {
      q = q.where('type', isEqualTo: _selectedPropertyTypes.first);
    }
    if (_selectedBHK.length == 1) {
      q = q.where('bhk', isEqualTo: _selectedBHK.first);
    }
    if (_selectedFurnishedStatus.length == 1) {
      q = q.where('furnished', isEqualTo: _selectedFurnishedStatus.first);
    }

    // If sorting by "Newest First" and you store createdAt, prefer that
    if (_sortBy == 'Newest First') {
      // You can swap to 'publishedAt' if that's your field
      q = col
          .where('rent', isGreaterThanOrEqualTo: _priceRange.start.round())
          .where('rent', isLessThanOrEqualTo: _priceRange.end.round())
          .orderBy('createdAt', descending: true);
      // NOTE: if you keep the single-value filters above, you'll likely need a composite index.
      if (_selectedPropertyTypes.length == 1) {
        q = q.where('type', isEqualTo: _selectedPropertyTypes.first);
      }
      if (_selectedBHK.length == 1) {
        q = q.where('bhk', isEqualTo: _selectedBHK.first);
      }
      if (_selectedFurnishedStatus.length == 1) {
        q = q.where('furnished', isEqualTo: _selectedFurnishedStatus.first);
      }
    }

    // You can add .limit(50) and implement pagination later if needed.
    return q.limit(60);
  }

  /// Map a Firestore doc to the shape that SearchResultsWidget expects.
  Map<String, dynamic> _mapDocToCard(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final title = _asString(d['title'], def: 'Property');
    final rent = _asInt(d['rent'], def: 0);
    final price = rent > 0 ? '₹$rent/month' : '—';
    final location = _asString(d['locationText'], def: '');
    final images = _asStringList(d['images']);
    final primary = _asString(d['primaryImageUrl'],
        def: images.isNotEmpty ? images.first : '');
    final image =
        primary.isNotEmpty ? primary : (images.isNotEmpty ? images.first : '');
    return {
      'id': doc.id,
      'title': title,
      'price': price,
      'location': location,
      'bhk': _asString(d['bhk'], def: ''),
      'type': _asString(d['type'], def: ''),
      'furnished': _asString(d['furnished'], def: ''),
      'image': image,
      'isVerified': (d['isVerified'] == true),
      // optional fields the widgets handle gracefully when missing:
      'distance': '', // if you ever compute it
    };
  }

  /// Client-side refine after query: search text, multi-select filters, and sorting.
  List<Map<String, dynamic>> _refineClientSide(
    List<Map<String, dynamic>> items,
  ) {
    var list = List<Map<String, dynamic>>.from(items);

    // search by title/location (case-insensitive "contains")
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final t = _asString(p['title']).toLowerCase();
        final loc = _asString(p['location']).toLowerCase();
        return t.contains(q) || loc.contains(q);
      }).toList();
    }

    // multi BHK filter (client-side if >1 selected)
    if (_selectedBHK.isNotEmpty) {
      list = list
          .where((p) => _selectedBHK.contains(_asString(p['bhk'])))
          .toList();
    }
    // multi Type filter
    if (_selectedPropertyTypes.isNotEmpty) {
      list = list
          .where((p) => _selectedPropertyTypes.contains(_asString(p['type'])))
          .toList();
    }
    // multi Furnished filter
    if (_selectedFurnishedStatus.isNotEmpty) {
      list = list
          .where((p) =>
              _selectedFurnishedStatus.contains(_asString(p['furnished'])))
          .toList();
    }

    // sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) {
          final pa = _asInt(a['price']);
          final pb = _asInt(b['price']);
          return pa.compareTo(pb);
        });
        break;
      case 'Price: High to Low':
        list.sort((a, b) {
          final pa = _asInt(a['price']);
          final pb = _asInt(b['price']);
          return pb.compareTo(pa);
        });
        break;
      case 'Newest First':
        // already ordered server-side if you have createdAt; if not, keep as-is
        break;
      case 'Distance':
        // you can implement if you compute distance; for now leave as-is or shuffle
        break;
      case 'Relevance':
      default:
        // keep original server order
        break;
    }

    // keep only properties within priceRange again (safety if server sort changed it)
    list = list.where((p) {
      final numeric = _asInt(p['price']);
      return numeric >= _priceRange.start && numeric <= _priceRange.end;
    }).toList();

    return list;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Container(
        child: Column(
          children: [
            SearchHeaderWidget(
              searchQuery: _searchQuery,
              onBackPressed: () => Navigator.pop(context),
              onLocationPressed: _handleLocationPressed,
              onSearchChanged: _handleSearchChanged,
            ),
            ActiveFiltersWidget(
              priceRange: _priceRange,
              selectedBHK: _selectedBHK,
              selectedPropertyTypes: _selectedPropertyTypes,
              selectedFurnishedStatus: _selectedFurnishedStatus,
              onRemoveFilter: _handleRemoveFilter,
              onClearAll: _handleClearAllFilters,
            ),
            FilterSectionWidget(
              priceRange: _priceRange,
              selectedBHK: _selectedBHK,
              selectedPropertyTypes: _selectedPropertyTypes,
              selectedFurnishedStatus: _selectedFurnishedStatus,
              onPriceRangeChanged: _handlePriceRangeChanged,
              onBHKChanged: _handleBHKChanged,
              onPropertyTypesChanged: _handlePropertyTypesChanged,
              onFurnishedStatusChanged: _handleFurnishedStatusChanged,
              onMoreFiltersPressed: _handleMoreFiltersPressed,
              onClearAllPressed: _handleClearAllFilters,
            ),
        
            // RESULTS (live from Firestore)
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _buildQuery().snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Text(
                          'Failed to load properties.\n${snap.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
        
                  final docs = snap.data?.docs ?? const [];
                  final items = docs.map(_mapDocToCard).toList();
                  final refined = _refineClientSide(items);
        
                  // update count shown in bottom bar
                  if (_resultCount != refined.length) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _resultCount = refined.length);
                    });
                  }
        
                  if (_isMapView) {
                    return MapViewWidget(
                      properties: refined,
                      onPropertyTap: _handlePropertyTap,
                    );
                  }
        
                  return SearchResultsWidget(
                    properties: refined,
                    isGridView: _isGridView,
                    sortBy: _sortBy,
                    onToggleView: _handleToggleView,
                    onSortChanged: _handleSortChanged,
                    onPropertyTap: _handlePropertyTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      floatingActionButton: _buildMapToggleFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ---------- bottom bar & FAB ----------
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handleApplyFilters,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Show $_resultCount Properties'),
        ),
      ),
    );
  }

  Widget _buildMapToggleFAB() {
    return FloatingActionButton.extended(
      onPressed: _handleToggleMapView,
      icon: CustomIconWidget(
        iconName: _isMapView ? 'list' : 'map',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: 20,
      ),
      label: Text(_isMapView ? 'List' : 'Map'),
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
    );
  }

  // ---------- handlers (unchanged API) ----------
  void _handleSearchChanged(String query) {
    setState(() => _searchQuery = query);
    // No manual fetch; StreamBuilder reacts to state (server + client filters)
  }

  void _handleLocationPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting current location...')),
    );
  }

  void _handlePriceRangeChanged(RangeValues range) {
    setState(() => _priceRange = range);
  }

  void _handleBHKChanged(List<String> bhkList) {
    setState(() => _selectedBHK = bhkList);
  }

  void _handlePropertyTypesChanged(List<String> types) {
    setState(() => _selectedPropertyTypes = types);
  }

  void _handleFurnishedStatusChanged(List<String> status) {
    setState(() => _selectedFurnishedStatus = status);
  }

  void _handleMoreFiltersPressed() => _showAdvancedFiltersBottomSheet();

  void _handleRemoveFilter(String filterKey) {
    if (filterKey == 'price') {
      _priceRange = const RangeValues(5000, 100000);
    } else if (filterKey.startsWith('bhk_')) {
      _selectedBHK.remove(filterKey.substring(4));
    } else if (filterKey.startsWith('type_')) {
      _selectedPropertyTypes.remove(filterKey.substring(5));
    } else if (filterKey.startsWith('furnished_')) {
      _selectedFurnishedStatus.remove(filterKey.substring(10));
    }
    setState(() {});
  }

  void _handleClearAllFilters() {
    setState(() {
      _priceRange = const RangeValues(5000, 100000);
      _selectedBHK.clear();
      _selectedPropertyTypes.clear();
      _selectedFurnishedStatus.clear();
      _searchQuery = '';
    });
  }

  void _handleToggleView() => setState(() => _isGridView = !_isGridView);
  void _handleToggleMapView() => setState(() => _isMapView = !_isMapView);

  void _handleSortChanged(String sortBy) {
    setState(() => _sortBy = sortBy);
  }

  void _handlePropertyTap(Map<String, dynamic> property) {
    final id = _asString(property['id']);
    if (id.isNotEmpty) {
      Navigator.pushNamed(context, '/property-detail-screen',
          arguments: {'propertyId': id});
    } else {
      Navigator.pushNamed(context, '/property-detail-screen');
    }
  }

  void _handleApplyFilters() {
    // No extra work; StreamBuilder + client filters react to state.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing $_resultCount properties')),
    );
  }

  // ---------- Advanced Filters Sheet (unchanged) ----------
  void _showAdvancedFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advanced Filters',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildAdvancedFilterSection('Amenities', [
                    'Parking',
                    'Gym',
                    'Swimming Pool',
                    'Security',
                    'Garden',
                    'Elevator'
                  ]),
                  SizedBox(height: 3.h),
                  _buildAdvancedFilterSection('Availability', [
                    'Immediately',
                    'Within 15 days',
                    'Within 30 days',
                    'After 30 days'
                  ]),
                  SizedBox(height: 3.h),
                  _buildAdvancedFilterSection('Property Age', [
                    'Under 1 year',
                    '1-5 years',
                    '5-10 years',
                    'Above 10 years'
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: false,
              onSelected: (selected) {
                // future: wire to your state
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

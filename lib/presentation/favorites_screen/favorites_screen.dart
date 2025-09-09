import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_favorites_widget.dart';
import './widgets/favorites_grid_widget.dart';
import './widgets/favorites_header_widget.dart';
import './widgets/favorites_search_widget.dart';
import './widgets/sort_options_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // UI state
  String _searchQuery = '';
  String _sortBy = 'Recently Added';
  String _priceRange = 'All';
  int _currentBottomIndex = 2;
  
  final List<String> _sortOptions = [
    'Recently Added',
    'Price Low-High',
    'Price High-Low',
    'Distance', // (optional if you store distance)
  ];
  final List<String> _priceRanges = ['All', '₹0-25k', '₹25k-50k', '₹50k+'];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference<Map<String, dynamic>>? get _favRef => _uid == null
      ? null
      : FirebaseFirestore.instance
          .collection('toletforrent_users')
          .doc(_uid)
          .collection('favorites');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  int _extractPrice(String priceString) {
    final numberString = priceString.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(numberString) ?? 0;
  }

  bool _matchesPriceRange(String price, String range) {
    final priceValue = _extractPrice(price);
    switch (range) {
      case '₹0-25k':
        return priceValue <= 25000;
      case '₹25k-50k':
        return priceValue > 25000 && priceValue <= 50000;
      case '₹50k+':
        return priceValue > 50000;
      default:
        return true;
    }
  }

  double _extractDistance(String distanceString) {
    final numberString = distanceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numberString) ?? 0.0;
  }

  List<List<String>> _chunk(List<String> ids, {int size = 10}) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      chunks.add(ids.sublist(i, i + size > ids.length ? ids.length : i + size));
    }
    return chunks;
  }

  // Turn Firestore property doc into the map your grid expects
  Map<String, dynamic> _toCardMap(
      DocumentSnapshot<Map<String, dynamic>> doc, DateTime addedAt) {
    final d = doc.data() ?? const {};
    final rent = d['rent'];
    final price = (rent is num && rent > 0) ? '₹${rent.toInt()}/month' : '—';

    // Pick an image safely
    String primary = '';
    if (d['primaryImageUrl'] is String &&
        (d['primaryImageUrl'] as String).isNotEmpty) {
      primary = d['primaryImageUrl'];
    } else if (d['images'] is List && (d['images'] as List).isNotEmpty) {
      primary = (d['images'] as List).first.toString();
    }

    return {
      "id": doc.id,
      "price": price,
      "location": (d['locationText'] ?? '—').toString(),
      "bhk": (d['bhk'] ?? '—').toString(),
      "type": (d['type'] ?? '—').toString(),
      "area": (d['area'] ?? '').toString(),
      "image": primary,
      "isVerified": (d['isVerified'] ?? false) == true,
      "isFavorite": true,
      "availability": (d['status'] ?? 'Available').toString(),
      // Optional: only if you store it; otherwise provide '' so sorting skips it
      "distance": (d['distance'] ?? '').toString(),
      "dateAdded": addedAt,
    };
  }

  // Fetch a batch of properties for a list of IDs (single shot)
  Future<List<Map<String, dynamic>>> _fetchPropertiesForIds(
    List<String> propIds,
    Map<String, DateTime> addedAtById,
  ) async {
    if (propIds.isEmpty) return [];
    final props = <Map<String, dynamic>>[];

    for (final ids in _chunk(propIds, size: 10)) {
      final qs = await FirebaseFirestore.instance
          .collection('properties')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
      for (final doc in qs.docs) {
        final addedAt = addedAtById[doc.id] ?? DateTime.now();
        props.add(_toCardMap(doc, addedAt));
      }
    }
    return props;
  }

  // ---------- Actions ----------
  void _onSearchChanged(String query) => setState(() => _searchQuery = query);

  void _onSortChanged(String sortBy) => setState(() => _sortBy = sortBy);

  Future<void> _removeFromFavorites(String propertyId) async {
    if (_favRef == null) return;
    await _favRef!.doc(propertyId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Property removed from favorites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _favRef!.doc(propertyId).set({
                'propertyId': propertyId,
                'addedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            },
          ),
        ),
      );
    }
  }

  void _onPropertyTap(Map<String, dynamic> property) {
    Navigator.pushNamed(
      context,
      '/property-detail-screen',
      arguments: {'propertyId': property['id'] as String},
    );
  }

  void _onFavoriteTap(Map<String, dynamic> property) {
    final id = property['id'] as String;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Favorites',
            style: AppTheme.lightTheme.textTheme.titleMedium),
        content: Text(
          'Are you sure you want to remove this property from your favorites?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeFromFavorites(id);
              },
              child: const Text('Remove')),
        ],
      ),
    );
  }

  void _onShareTap(Map<String, dynamic> property) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Property link copied to clipboard')),
    );
  }

  void _onContactTap(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactBottomSheet(property),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentBottomIndex) return;
    setState(() => _currentBottomIndex = index);

    final routes = [
      '/home-screen',
      '/property-search-screen',
      null, //current
      '/messages-screen',
      '/profile-screen',
    ];
    
    final r = routes[index];
    if (r != null) Navigator.pushReplacementNamed(context, r);
  }

  void _onStartBrowsing() {
    Navigator.pushReplacementNamed(context, '/home-screen');
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    if (_uid == null || _favRef == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Text(
              'Please sign in to view your favorites.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: _currentBottomIndex,
          onTap: _onBottomNavTap,
          variant: BottomBarVariant.standard,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _favRef!
              .orderBy('addedAt', descending: true)
              .snapshots(), // live favorites list
          builder: (context, favSnap) {
            if (favSnap.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton();
            }
            final favDocs = favSnap.data?.docs ?? const [];
            if (favDocs.isEmpty) {
              return Column(
                children: [
                  FavoritesHeaderWidget(totalCount: 0),
                  Expanded(
                      child: EmptyFavoritesWidget(
                          onStartBrowsing: _onStartBrowsing)),
                ],
              );
            }

            // Build map of id -> addedAt
            final addedAtById = <String, DateTime>{};
            final ids = <String>[];
            for (final d in favDocs) {
              ids.add(d.id); // favorite doc id == propertyId
              final ts = d.data()['addedAt'];
              final when = (ts is Timestamp) ? ts.toDate() : DateTime.now();
              addedAtById[d.id] = when;
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              // Single-shot fetch of all properties for these ids (re-runs whenever favs change)
              future: _fetchPropertiesForIds(ids, addedAtById),
              builder: (context, propSnap) {
                final loading =
                    propSnap.connectionState == ConnectionState.waiting;
                final items = propSnap.data ?? <Map<String, dynamic>>[];

                // Header + search/sort controls
                final header = FavoritesHeaderWidget(totalCount: ids.length);
                final controls = Column(
                  children: [
                    FavoritesSearchWidget(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClearTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                    SortOptionsWidget(
                      sortBy: _sortBy,
                      sortOptions: _sortOptions,
                      priceRange: _priceRange,
                      priceRanges: _priceRanges,
                      onSortChanged: _onSortChanged,
                      onPriceRangeChanged: (range) =>
                          setState(() => _priceRange = range),
                    ),
                  ],
                );

                // Filter + sort locally for UI
                List<Map<String, dynamic>> filtered = items.where((p) {
                  final q = _searchQuery.toLowerCase();
                  final matchesSearch = q.isEmpty ||
                      (p['location'] as String).toLowerCase().contains(q) ||
                      (p['bhk'] as String).toLowerCase().contains(q) ||
                      (p['type'] as String).toLowerCase().contains(q);
                  final matchesPrice =
                      _matchesPriceRange(p['price'] as String, _priceRange);
                  return matchesSearch && matchesPrice;
                }).toList();

                switch (_sortBy) {
                  case 'Recently Added':
                    filtered.sort((a, b) => (b['dateAdded'] as DateTime)
                        .compareTo(a['dateAdded'] as DateTime));
                    break;
                  case 'Price Low-High':
                    filtered.sort((a, b) => _extractPrice(a['price'] as String)
                        .compareTo(_extractPrice(b['price'] as String)));
                    break;
                  case 'Price High-Low':
                    filtered.sort((a, b) => _extractPrice(b['price'] as String)
                        .compareTo(_extractPrice(a['price'] as String)));
                    break;
                  case 'Distance':
                    filtered.sort((a, b) =>
                        _extractDistance((a['distance'] as String? ?? ''))
                            .compareTo(_extractDistance(
                                (b['distance'] as String? ?? ''))));
                    break;
                }

                return  
                RefreshIndicator(
                  onRefresh: () async {

                  }, // Firestore is realtime
                  child: Column(
                    children: [
                      header,
                      controls,
                      Expanded(
                        child: loading
                            ? _buildLoadingState()
                            : filtered.isEmpty
                                ? _buildNoResultsState()
                                : FavoritesGridWidget(
                                    properties: filtered,
                                    onPropertyTap: _onPropertyTap,
                                    onFavoriteTap: _onFavoriteTap,
                                    onShareTap: _onShareTap,
                                    onContactTap: _onContactTap,
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        variant: BottomBarVariant.standard,
      ),
    );
  }

  // ---------- UI bits ----------
  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        FavoritesHeaderWidget(totalCount: 0),
        Expanded(child: _buildLoadingState()),
      ],
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 100.w > 600 ? 3 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
          SizedBox(height: 2.h),
          Text(
            'No properties found',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search or filters',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 3.h),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _priceRange = 'All';
              });
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBottomSheet(Map<String, dynamic> property) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Text(
                  'Contact Owner',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  property['location'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calling owner...')),
                          );
                        },
                        icon: CustomIconWidget(
                          iconName: 'phone',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: const Text('Call'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Opening WhatsApp...')),
                          );
                        },
                        icon: CustomIconWidget(
                          iconName: 'chat',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        ),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

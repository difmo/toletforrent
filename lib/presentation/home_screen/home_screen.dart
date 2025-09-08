import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/category_chips_widget.dart';
import './widgets/featured_properties_carousel_widget.dart';
import './widgets/location_header_widget.dart';
import './widgets/property_grid_widget.dart';
import './widgets/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // UI state
  String _currentCity = 'Mumbai, Maharashtra';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentBottomIndex = 0;

  // Data
  final _db = FirebaseFirestore.instance;
  final int _pageSize = 10;

  List<Map<String, dynamic>> _featuredProperties = [];
  List<Map<String, dynamic>> _properties = []; // raw page data
  List<Map<String, dynamic>> _displayed = []; // category-filtered
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  // Favorites
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favSub;
  Set<String> _favoriteIds = {};

  final List<String> _categories = const [
    'All',
    '1 BHK',
    '2 BHK',
    '3 BHK+',
    'Furnished',
    'Unfurnished',
    'Studio',
    'Villa'
  ];
  final ScrollController _pageScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenFavorites();
    // infinite scroll on the single page
    _pageScroll.addListener(() {
      final pos = _pageScroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        if (_hasMore && !_isLoadingMore) {
          _loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _pageScroll.dispose(); // <-- dispose
    super.dispose();
    super.dispose();
  }

  // ------------ Firestore fetchers ------------

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchFeatured(),
        _fetchPage(reset: true),
      ]);
      _applyCategory();
    } catch (_) {
      // Optionally toast/log
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFeatured() async {
    // Try multiple strategies until one returns docs.
    final col = _db.collection('properties');

    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      // 1) explicit featured + recent
      col
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get(),
      // 2) just recent by createdAt
      col.orderBy('createdAt', descending: true).limit(6).get(),
      // 3) recent by updatedAt (if you have it)
      col.orderBy('updatedAt', descending: true).limit(6).get(),
      // 4) by rent (any field you’re sure exists)
      col.orderBy('rent', descending: true).limit(6).get(),
      // 5) no order – just give me something
      col.limit(6).get(),
    ];

    QuerySnapshot<Map<String, dynamic>>? snap;

    for (var i = 0; i < queries.length; i++) {
      try {
        final s = await queries[i];
        if (s.docs.isNotEmpty) {
          snap = s;
          debugPrint(
              '[Home] _fetchFeatured used strategy #$i with ${s.docs.length} docs');
          break;
        }
      } catch (e) {
        // ignore and try next
        debugPrint('[Home] _fetchFeatured strategy #$i failed: $e');
      }
    }

    _featuredProperties = (snap?.docs ?? []).map(_mapDocToCard).toList();
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_isLoadingMore) return;

    if (reset) {
      _lastDoc = null;
      _hasMore = true;
      _properties.clear();
    }
    if (!_hasMore) return;

    setState(() => _isLoadingMore = true);

    final col = _db.collection('properties');

    // Build candidate queries (we’ll pick the first that returns docs).
    List<Query<Map<String, dynamic>>> candidates = [
      col.orderBy('createdAt', descending: true),
      col.orderBy('updatedAt', descending: true),
      col.orderBy('rent', descending: true),
      col, // no order
    ];

    // Apply paging cursor and limit to each candidate
    List<Future<QuerySnapshot<Map<String, dynamic>>>> attempts =
        candidates.map((q) {
      var qq = q.limit(_pageSize);
      if (_lastDoc != null) {
        try {
          // startAfterDocument only works if the orderBy field is consistent,
          // so this may throw for the "no order" candidate – that's fine.
          qq = qq.startAfterDocument(_lastDoc!);
        } catch (_) {}
      }
      return qq.get();
    }).toList();

    QuerySnapshot<Map<String, dynamic>>? snap;

    for (var i = 0; i < attempts.length; i++) {
      try {
        final s = await attempts[i];
        if (s.docs.isNotEmpty) {
          snap = s;
          debugPrint(
              '[Home] _fetchPage used strategy #$i; got ${s.docs.length}');
          break;
        }
      } catch (e) {
        debugPrint('[Home] _fetchPage strategy #$i failed: $e');
      }
    }

    if (snap != null && snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _properties.addAll(snap.docs.map(_mapDocToCard));
      if (snap.docs.length < _pageSize) _hasMore = false;
    } else {
      // no docs from any strategy -> no more results
      _hasMore = false;
    }

    _applyCategory();
    if (mounted) setState(() => _isLoadingMore = false);
  }
  // ------------ Favorites sync ------------

  void _listenFavorites() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _favSub = _db
        .collection('toletforrent_users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((qs) {
      _favoriteIds = qs.docs.map((d) => d.id).toSet();
      // re-mark items
      _featuredProperties = _featuredProperties
          .map((e) => {...e, 'isFavorite': _favoriteIds.contains(e['id'])})
          .toList();
      _properties = _properties
          .map((e) => {...e, 'isFavorite': _favoriteIds.contains(e['id'])})
          .toList();
      _applyCategory();
      if (mounted) setState(() {});
    });
  }

  // ------------ Mapping helpers ------------

  Map<String, dynamic> _mapDocToCard(
      QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final images = (data['images'] is List)
        ? (data['images'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList()
        : <String>[];
    final imageUrl =
        (data['primaryImageUrl']?.toString().trim().isNotEmpty ?? false)
            ? data['primaryImageUrl'].toString()
            : (images.isNotEmpty ? images.first : '');

    final rent = (data['rent'] is num) ? (data['rent'] as num).toInt() : 0;
    final price = rent > 0 ? '₹$rent/month' : '—';

    final location =
        (data['locationText']?.toString().trim().isNotEmpty ?? false)
            ? data['locationText'].toString()
            : (data['address']?.toString() ?? '—');

    final bhk = data['bhk']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final isVerified = (data['isVerified'] == true);

    final ts = data['availabilityDate'];
    String availability = 'Available';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      if (dt.isAfter(DateTime.now())) {
        availability =
            'From ${dt.day.toString().padLeft(2, '0')} ${_month3(dt.month)}';
      }
    }

    final id = d.id;
    final isFav = _favoriteIds.contains(id);

    return {
      "id": id,
      "price": price,
      "location": location,
      "bhk": bhk.isNotEmpty ? bhk : '—',
      "type": type.isNotEmpty ? type : '—',
      "area": (data['area']?.toString() ?? ''),
      "image":
          imageUrl, // CustomImageWidget should handle empty -> placeholder gracefully
      "isVerified": isVerified,
      "isFavorite": isFav,
      "availability": availability,
      // optional fields your widgets may ignore if absent:
      "distance": "", // compute later if you add geolocation
    };
  }

  String _month3(int m) {
    const mm = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return (m >= 1 && m <= 12) ? mm[m - 1] : '';
  }

  // ------------ UI actions ------------

  Future<void> _refreshData() async {
    await _fetchFeatured();
    await _fetchPage(reset: true);
  }

  Future<void> _loadMore() => _fetchPage(reset: false);

  void _onLocationTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationBottomSheet(),
    );
  }

  void _onSearchTap() {
    Navigator.pushNamed(context, '/property-search-screen');
  }

  void _onFilterTap() {
    Navigator.pushNamed(context, '/property-search-screen');
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _applyCategory();
  }

  void _applyCategory() {
    List<Map<String, dynamic>> src = List.from(_properties);
    switch (_selectedCategory) {
      case '1 BHK':
        src = src.where((p) => (p['bhk'] as String).startsWith('1')).toList();
        break;
      case '2 BHK':
        src = src.where((p) => (p['bhk'] as String).startsWith('2')).toList();
        break;
      case '3 BHK+':
        src = src.where((p) {
          final s = (p['bhk'] as String).trim().toLowerCase();
          return s.startsWith('3') || s.startsWith('4') || s.contains('4+');
        }).toList();
        break;
      case 'Furnished':
        // If you have furnished info, map & check here; otherwise skip
        break;
      case 'Unfurnished':
        break;
      case 'Studio':
        src = src
            .where(
                (p) => (p['type'] as String).toLowerCase().contains('studio'))
            .toList();
        break;
      case 'Villa':
        src = src
            .where((p) => (p['type'] as String).toLowerCase().contains('villa'))
            .toList();
        break;
      default:
        // 'All'
        break;
    }
    _displayed = src
        .map((e) => {...e, 'isFavorite': _favoriteIds.contains(e['id'])})
        .toList();
    if (mounted) setState(() {});
  }

  void _onPropertyTap(Map<String, dynamic> property) {
    Navigator.pushNamed(context, '/property-detail-screen',
        arguments: {'propertyId': property['id']});
  }

  Future<void> _onFavoriteTap(Map<String, dynamic> property) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save favorites')),
      );
      return;
    }
    final id = property['id'] as String;
    final favRef = _db
        .collection('toletforrent_users')
        .doc(uid)
        .collection('favorites')
        .doc(id);
    final isFav = _favoriteIds.contains(id);

    try {
      if (isFav) {
        await favRef.delete();
        _favoriteIds.remove(id);
      } else {
        await favRef.set({
          'addedAt': FieldValue.serverTimestamp(),
          'propertyId': id,
        });
        _favoriteIds.add(id);
      }
      // update local lists for instant UI
      _featuredProperties = _featuredProperties
          .map((e) => e['id'] == id ? {...e, 'isFavorite': !isFav} : e)
          .toList();
      _properties = _properties
          .map((e) => e['id'] == id ? {...e, 'isFavorite': !isFav} : e)
          .toList();
      _applyCategory();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    }
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

  void _onPostPropertyTap() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushNamed(context, '/add-property-screen');
    } else {
      Navigator.pushNamed(context, '/authentication-screen');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentBottomIndex = index);
    // Navigate if you have routes per tab
  }

  // ------------ UI ------------
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        // ONE scrollable for the entire page
        child: SingleChildScrollView(
          controller: _pageScroll,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Header
              LocationHeaderWidget(
                currentCity: _currentCity,
                onLocationTap: _onLocationTap,
              ),

              // Search Bar
              SearchBarWidget(
                onTap: _onSearchTap,
                onFilterTap: _onFilterTap,
              ),

              // Featured
              if (!_isLoading && _featuredProperties.isNotEmpty)
                FeaturedPropertiesCarouselWidget(
                  featuredProperties: _featuredProperties,
                  onPropertyTap: _onPropertyTap,
                ),

              SizedBox(height: 2.h),

              // Category chips
              CategoryChipsWidget(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),

              // Content (non-scrollable grid embedded in page)
              if (_isLoading)
                _buildLoadingStateEmbedded()
              else
                PropertyGridWidget(
                  properties: _displayed,
                  onPropertyTap: _onPropertyTap,
                  onFavoriteTap: _onFavoriteTap,
                  onShareTap: _onShareTap,
                  onContactTap: _onContactTap,
                  onLoadMore: null,       // page-level load more handles it
                  isLoading: false,
                  embedded: true,         // <<< make it non-scrollable inside page
                ),

              if (_isLoadingMore) ...[
                SizedBox(height: 2.h),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],

              // spacing so last card isn't hidden behind bottom bar/FAB
              SizedBox(height: kBottomNavigationBarHeight + 24),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: Container(
      decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
        AppTheme.lightTheme.colorScheme.primary,
        AppTheme.lightTheme.colorScheme.secondary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
        ),
      ],
      ),
      child: FloatingActionButton.extended(
      onPressed: _onPostPropertyTap,
      backgroundColor: Colors.transparent,
      elevation: 0,
      icon: CustomIconWidget(
        iconName: 'add_home',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: 20,
      ),
      label: Text(
        'Post Property',
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
        ),
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

Widget _buildLoadingStateEmbedded() {
  return Column(
    children: [
      // Featured skeleton
      Container(
        height: 35.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Chips skeleton
      Container(
        height: 6.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (context, index) => SizedBox(width: 2.w),
          itemBuilder: (context, index) => Container(
            width: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      SizedBox(height: 2.h),
      // Grid skeleton (non-scrollable)
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
        ),
      ),
    ],
  );
}

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Featured skeleton
        Container(
          height: 35.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Category chips skeleton
        Container(
          height: 6.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => SizedBox(width: 2.w),
            itemBuilder: (context, index) => Container(
              width: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        // Grid skeleton
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
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
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBottomSheet(){
    final cities = [
      'Mumbai, Maharashtra',
      'Delhi, NCR',
      'Bangalore, Karnataka',
      'Hyderabad, Telangana',
      'Chennai, Tamil Nadu',
      'Pune, Maharashtra',
      'Kolkata, West Bengal',
      'Ahmedabad, Gujarat',
    ];

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
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
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select City',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: cities.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = city == _currentCity;

                return ListTile(
                  leading: CustomIconWidget(
                    iconName: 'location_city',
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                    size: 24,
                  ),
                  title: Text(
                    city,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : null,
                    ),
                  ),
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _currentCity = city;
                    });
                    // Optional: requery Firestore with a city filter if you maintain such a field
                    Navigator.pop(context);
                  },
                );
              },
            ),
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
                  (property['location'] as String?) ?? '',
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

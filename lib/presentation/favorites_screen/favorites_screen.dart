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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'Recently Added';
  String _priceRange = 'All';
  int _currentBottomIndex = 2; // Favorites tab active

  // Mock data for favorite properties
  List<Map<String, dynamic>> _favoriteProperties = [
    {
      "id": 2,
      "price": "₹45,000/month",
      "location": "Powai, Mumbai",
      "bhk": "3 BHK",
      "type": "Villa",
      "area": "1200",
      "image":
          "https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": true,
      "availability": "Available",
      "distance": "4.2 km",
      "dateAdded": DateTime.now().subtract(const Duration(days: 2))
    },
    {
      "id": 5,
      "price": "₹35,000/month",
      "location": "Juhu, Mumbai",
      "bhk": "3 BHK",
      "type": "Apartment",
      "area": "1100",
      "image":
          "https://images.pexels.com/photos/1571468/pexels-photo-1571468.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": true,
      "availability": "Available",
      "distance": "4.2 km",
      "dateAdded": DateTime.now().subtract(const Duration(days: 5))
    },
    {
      "id": 8,
      "price": "₹52,000/month",
      "location": "Worli, Mumbai",
      "bhk": "3 BHK",
      "type": "Penthouse",
      "area": "1500",
      "image":
          "https://images.pexels.com/photos/1571473/pexels-photo-1571473.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": true,
      "availability": "Available",
      "distance": "6.3 km",
      "dateAdded": DateTime.now().subtract(const Duration(days: 1))
    },
    {
      "id": 10,
      "price": "₹28,000/month",
      "location": "Bandra East, Mumbai",
      "bhk": "2 BHK",
      "type": "Apartment",
      "area": "900",
      "image":
          "https://images.pexels.com/photos/1396132/pexels-photo-1396132.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": true,
      "availability": "Available",
      "distance": "3.8 km",
      "dateAdded": DateTime.now().subtract(const Duration(days: 7))
    },
  ];

  List<Map<String, dynamic>> _filteredProperties = [];
  final List<String> _sortOptions = [
    'Recently Added',
    'Price Low-High',
    'Price High-Low',
    'Distance'
  ];
  final List<String> _priceRanges = ['All', '₹0-25k', '₹25k-50k', '₹50k+'];

  @override
  void initState() {
    super.initState();
    _filteredProperties = List.from(_favoriteProperties);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      // Refresh favorite properties data
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    _filterProperties();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _sortProperties();
  }

  void _filterProperties() {
    setState(() {
      _filteredProperties = _favoriteProperties.where((property) {
        final matchesSearch = _searchQuery.isEmpty ||
            property['location']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            property['bhk']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            property['type']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesPrice = _priceRange == 'All' ||
            _matchesPriceRange(property['price'], _priceRange);

        return matchesSearch && matchesPrice;
      }).toList();
    });
    _sortProperties();
  }

  void _sortProperties() {
    setState(() {
      switch (_sortBy) {
        case 'Recently Added':
          _filteredProperties
              .sort((a, b) => b['dateAdded'].compareTo(a['dateAdded']));
          break;
        case 'Price Low-High':
          _filteredProperties.sort((a, b) =>
              _extractPrice(a['price']).compareTo(_extractPrice(b['price'])));
          break;
        case 'Price High-Low':
          _filteredProperties.sort((a, b) =>
              _extractPrice(b['price']).compareTo(_extractPrice(a['price'])));
          break;
        case 'Distance':
          _filteredProperties.sort((a, b) => _extractDistance(a['distance'])
              .compareTo(_extractDistance(b['distance'])));
          break;
      }
    });
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

  int _extractPrice(String priceString) {
    final numberString = priceString.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(numberString) ?? 0;
  }

  double _extractDistance(String distanceString) {
    final numberString = distanceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numberString) ?? 0.0;
  }

  void _onPropertyTap(Map<String, dynamic> property) {
    Navigator.pushNamed(context, '/property-detail-screen',
        arguments: property);
  }

  void _onFavoriteTap(Map<String, dynamic> property) {
    _showRemoveDialog(property);
  }

  void _showRemoveDialog(Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove from Favorites',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Are you sure you want to remove this property from your favorites?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromFavorites(property);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeFromFavorites(Map<String, dynamic> property) {
    setState(() {
      _favoriteProperties.removeWhere((p) => p['id'] == property['id']);
      _filteredProperties.removeWhere((p) => p['id'] == property['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Property removed from favorites'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _favoriteProperties.add(property);
              _filterProperties();
            });
          },
        ),
      ),
    );
  }

  void _onShareTap(Map<String, dynamic> property) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
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
    if (index != _currentBottomIndex) {
      setState(() {
        _currentBottomIndex = index;
      });

      final routes = [
        '/home-screen',
        '/property-search-screen',
        null, // Current screen
        '/home-screen', // Messages (temporary)
        '/authentication-screen',
      ];

      if (routes[index] != null) {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  void _onStartBrowsing() {
    Navigator.pushReplacementNamed(context, '/home-screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // Header
              FavoritesHeaderWidget(
                totalCount: _favoriteProperties.length,
              ),

              if (_favoriteProperties.isNotEmpty) ...[
                // Search and Sort
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
                  onPriceRangeChanged: (range) {
                    setState(() {
                      _priceRange = range;
                    });
                    _filterProperties();
                  },
                ),
              ],

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _favoriteProperties.isEmpty
                        ? EmptyFavoritesWidget(
                            onStartBrowsing: _onStartBrowsing,
                          )
                        : _filteredProperties.isEmpty
                            ? _buildNoResultsState()
                            : FavoritesGridWidget(
                                properties: _filteredProperties,
                                onPropertyTap: _onPropertyTap,
                                onFavoriteTap: _onFavoriteTap,
                                onShareTap: _onShareTap,
                                onContactTap: _onContactTap,
                              ),
              ),
            ],
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
                _filterProperties();
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

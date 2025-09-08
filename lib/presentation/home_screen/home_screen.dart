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
  final ScrollController _scrollController = ScrollController();
  final RefreshIndicator _refreshIndicatorKey = RefreshIndicator(
    onRefresh: () async {},
    child: const SizedBox(),
  );

  String _currentCity = 'Mumbai, Maharashtra';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentBottomIndex = 0;

  // Mock data for featured properties
  final List<Map<String, dynamic>> _featuredProperties = [
    {
      "id": 1,
      "price": "₹25,000/month",
      "location": "Bandra West, Mumbai",
      "bhk": "2 BHK",
      "type": "Apartment",
      "area": "850",
      "image":
          "https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": false,
      "availability": "Available"
    },
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
      "availability": "Available"
    },
    {
      "id": 3,
      "price": "₹18,000/month",
      "location": "Andheri East, Mumbai",
      "bhk": "1 BHK",
      "type": "Studio",
      "area": "450",
      "image":
          "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": false,
      "isFavorite": false,
      "availability": "Available"
    },
  ];

  // Mock data for property grid
  List<Map<String, dynamic>> _properties = [
    {
      "id": 4,
      "price": "₹22,000/month",
      "location": "Malad West, Mumbai",
      "bhk": "2 BHK",
      "type": "Apartment",
      "area": "750",
      "image":
          "https://images.pexels.com/photos/1571453/pexels-photo-1571453.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": false,
      "availability": "Available",
      "distance": "2.5 km"
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
      "distance": "4.2 km"
    },
    {
      "id": 6,
      "price": "₹15,000/month",
      "location": "Goregaon West, Mumbai",
      "bhk": "1 BHK",
      "type": "Studio",
      "area": "400",
      "image":
          "https://images.pexels.com/photos/1571471/pexels-photo-1571471.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": false,
      "isFavorite": false,
      "availability": "Available",
      "distance": "3.8 km"
    },
    {
      "id": 7,
      "price": "₹28,000/month",
      "location": "Kandivali East, Mumbai",
      "bhk": "2 BHK",
      "type": "Apartment",
      "area": "800",
      "image":
          "https://images.pexels.com/photos/1571472/pexels-photo-1571472.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": true,
      "isFavorite": false,
      "availability": "Occupied",
      "distance": "5.1 km"
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
      "distance": "6.3 km"
    },
    {
      "id": 9,
      "price": "₹19,500/month",
      "location": "Borivali West, Mumbai",
      "bhk": "1 BHK",
      "type": "Apartment",
      "area": "500",
      "image":
          "https://images.pexels.com/photos/1571474/pexels-photo-1571474.jpeg?auto=compress&cs=tinysrgb&w=800",
      "isVerified": false,
      "isFavorite": false,
      "availability": "Available",
      "distance": "8.7 km"
    },
  ];

  final List<String> _categories = [
    'All',
    '1 BHK',
    '2 BHK',
    '3 BHK+',
    'Furnished',
    'Unfurnished',
    'Studio',
    'Villa'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    // Simulate refresh
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      // Refresh data
    });
  }

  Future<void> _loadMoreProperties() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading more properties
    await Future.delayed(const Duration(milliseconds: 1000));

    final moreProperties = [
      {
        "id": _properties.length + 1,
        "price": "₹31,000/month",
        "location": "Thane West, Mumbai",
        "bhk": "2 BHK",
        "type": "Apartment",
        "area": "900",
        "image":
            "https://images.pexels.com/photos/1571475/pexels-photo-1571475.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isVerified": true,
        "isFavorite": false,
        "availability": "Available",
        "distance": "12.4 km"
      },
      {
        "id": _properties.length + 2,
        "price": "₹24,500/month",
        "location": "Navi Mumbai",
        "bhk": "2 BHK",
        "type": "Apartment",
        "area": "750",
        "image":
            "https://images.pexels.com/photos/1571476/pexels-photo-1571476.jpeg?auto=compress&cs=tinysrgb&w=800",
        "isVerified": false,
        "isFavorite": false,
        "availability": "Available",
        "distance": "15.2 km"
      },
    ];

    setState(() {
      _properties.addAll(moreProperties);
      _isLoadingMore = false;
    });
  }

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
    setState(() {
      _selectedCategory = category;
    });

    // Filter properties based on category
    _filterPropertiesByCategory(category);
  }

  void _filterPropertiesByCategory(String category) {
    // Implement filtering logic here
    // For now, just showing a snackbar
    if (category != 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtering by $category'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onPropertyTap(Map<String, dynamic> property) {
    Navigator.pushNamed(context, '/property-detail-screen');
  }

  void _onFavoriteTap(Map<String, dynamic> property) {
    setState(() {
      property['isFavorite'] = !(property['isFavorite'] ?? false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(property['isFavorite'] == true
            ? 'Added to favorites'
            : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
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

  void _onPostPropertyTap() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushNamed(context, '/add-property-screen');
    } else {
      Navigator.pushNamed(context, '/authentication-screen');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });
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

              // Featured Properties Carousel
              if (!_isLoading && _featuredProperties.isNotEmpty)
                FeaturedPropertiesCarouselWidget(
                  featuredProperties: _featuredProperties,
                  onPropertyTap: _onPropertyTap,
                ),

              SizedBox(height: 2.h),

              // Category Chips
              CategoryChipsWidget(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),

              // Property Grid
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : PropertyGridWidget(
                        properties: _properties,
                        onPropertyTap: _onPropertyTap,
                        onFavoriteTap: _onFavoriteTap,
                        onShareTap: _onShareTap,
                        onContactTap: _onContactTap,
                        onLoadMore: _loadMoreProperties,
                        isLoading: _isLoadingMore,
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPostPropertyTap,
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
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        variant: BottomBarVariant.standard,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Featured properties skeleton
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

        // Property grid skeleton
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

  Widget _buildLocationBottomSheet() {
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
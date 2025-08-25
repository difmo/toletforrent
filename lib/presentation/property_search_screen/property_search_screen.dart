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
  RangeValues _priceRange = const RangeValues(10000, 50000);
  List<String> _selectedBHK = [];
  List<String> _selectedPropertyTypes = [];
  List<String> _selectedFurnishedStatus = [];
  bool _isGridView = false;
  bool _isMapView = false;
  String _sortBy = 'Relevance';
  int _resultCount = 0;

  final List<Map<String, dynamic>> _mockProperties = [
    {
      "id": 1,
      "title": "Spacious 2BHK Apartment in Koramangala",
      "price": "₹25,000/month",
      "location": "Koramangala 5th Block, Bangalore",
      "bhk": "2 BHK",
      "type": "Apartment",
      "furnished": "Fully Furnished",
      "image":
          "https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": true,
      "ownerName": "Rajesh Kumar",
      "ownerPhone": "+91 9876543210",
      "area": "1200 sq ft",
      "availableFrom": "Immediately",
      "deposit": "₹50,000",
      "amenities": ["Parking", "Gym", "Swimming Pool", "Security"],
      "description":
          "Beautiful 2BHK apartment with modern amenities in the heart of Koramangala. Close to metro station and IT parks.",
      "rating": 4.5,
      "reviews": 23,
    },
    {
      "id": 2,
      "title": "Modern 3BHK House in Whitefield",
      "price": "₹35,000/month",
      "location": "Whitefield, Bangalore",
      "bhk": "3 BHK",
      "type": "House",
      "furnished": "Semi Furnished",
      "image":
          "https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": true,
      "ownerName": "Priya Sharma",
      "ownerPhone": "+91 9876543211",
      "area": "1800 sq ft",
      "availableFrom": "15th Jan 2025",
      "deposit": "₹70,000",
      "amenities": ["Garden", "Parking", "Power Backup", "Water Supply"],
      "description":
          "Spacious 3BHK independent house with garden in peaceful Whitefield locality. Perfect for families.",
      "rating": 4.7,
      "reviews": 18,
    },
    {
      "id": 3,
      "title": "Luxury 1BHK Studio in Electronic City",
      "price": "₹18,000/month",
      "location": "Electronic City Phase 1, Bangalore",
      "bhk": "1 BHK",
      "type": "Studio",
      "furnished": "Fully Furnished",
      "image":
          "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": false,
      "ownerName": "Amit Patel",
      "ownerPhone": "+91 9876543212",
      "area": "650 sq ft",
      "availableFrom": "1st Feb 2025",
      "deposit": "₹36,000",
      "amenities": ["AC", "WiFi", "Laundry", "Housekeeping"],
      "description":
          "Modern studio apartment perfect for working professionals. Located near major IT companies.",
      "rating": 4.2,
      "reviews": 12,
    },
    {
      "id": 4,
      "title": "Comfortable PG for Working Professionals",
      "price": "₹12,000/month",
      "location": "BTM Layout, Bangalore",
      "bhk": "1 BHK",
      "type": "PG",
      "furnished": "Fully Furnished",
      "image":
          "https://images.pexels.com/photos/1571468/pexels-photo-1571468.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": true,
      "ownerName": "Sunita Reddy",
      "ownerPhone": "+91 9876543213",
      "area": "400 sq ft",
      "availableFrom": "Immediately",
      "deposit": "₹24,000",
      "amenities": ["Meals", "WiFi", "Laundry", "Security"],
      "description":
          "Well-maintained PG accommodation with all meals included. Safe and secure environment.",
      "rating": 4.0,
      "reviews": 35,
    },
    {
      "id": 5,
      "title": "Premium 4BHK Villa in Sarjapur",
      "price": "₹55,000/month",
      "location": "Sarjapur Road, Bangalore",
      "bhk": "4+ BHK",
      "type": "Villa",
      "furnished": "Unfurnished",
      "image":
          "https://images.pexels.com/photos/1396132/pexels-photo-1396132.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": true,
      "ownerName": "Vikram Singh",
      "ownerPhone": "+91 9876543214",
      "area": "2500 sq ft",
      "availableFrom": "1st March 2025",
      "deposit": "₹1,10,000",
      "amenities": [
        "Swimming Pool",
        "Garden",
        "Parking",
        "Security",
        "Club House"
      ],
      "description":
          "Luxurious 4BHK villa in gated community with world-class amenities. Perfect for large families.",
      "rating": 4.8,
      "reviews": 8,
    },
    {
      "id": 6,
      "title": "Cozy 2BHK Apartment in Indiranagar",
      "price": "₹28,000/month",
      "location": "Indiranagar, Bangalore",
      "bhk": "2 BHK",
      "type": "Apartment",
      "furnished": "Semi Furnished",
      "image":
          "https://images.pexels.com/photos/1571453/pexels-photo-1571453.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "isVerified": true,
      "ownerName": "Meera Joshi",
      "ownerPhone": "+91 9876543215",
      "area": "1100 sq ft",
      "availableFrom": "20th Jan 2025",
      "deposit": "₹56,000",
      "amenities": ["Balcony", "Parking", "Elevator", "Security"],
      "description":
          "Charming 2BHK apartment in vibrant Indiranagar with easy access to restaurants and shopping.",
      "rating": 4.3,
      "reviews": 19,
    },
  ];

  List<Map<String, dynamic>> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _filteredProperties = List.from(_mockProperties);
    _resultCount = _filteredProperties.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
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
          Expanded(
            child: _isMapView
                ? MapViewWidget(
                    properties: _filteredProperties,
                    onPropertyTap: _handlePropertyTap,
                  )
                : SearchResultsWidget(
                    properties: _filteredProperties,
                    isGridView: _isGridView,
                    sortBy: _sortBy,
                    onToggleView: _handleToggleView,
                    onSortChanged: _handleSortChanged,
                    onPropertyTap: _handlePropertyTap,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      floatingActionButton: _buildMapToggleFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

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
          child: Text('Show $_resultCount Properties'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _handleLocationPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting current location...')),
    );
  }

  void _handlePriceRangeChanged(RangeValues range) {
    setState(() {
      _priceRange = range;
    });
    _applyFilters();
  }

  void _handleBHKChanged(List<String> bhkList) {
    setState(() {
      _selectedBHK = bhkList;
    });
    _applyFilters();
  }

  void _handlePropertyTypesChanged(List<String> types) {
    setState(() {
      _selectedPropertyTypes = types;
    });
    _applyFilters();
  }

  void _handleFurnishedStatusChanged(List<String> status) {
    setState(() {
      _selectedFurnishedStatus = status;
    });
    _applyFilters();
  }

  void _handleMoreFiltersPressed() {
    _showAdvancedFiltersBottomSheet();
  }

  void _handleRemoveFilter(String filterKey) {
    if (filterKey == 'price') {
      setState(() {
        _priceRange = const RangeValues(5000, 100000);
      });
    } else if (filterKey.startsWith('bhk_')) {
      final bhk = filterKey.substring(4);
      setState(() {
        _selectedBHK.remove(bhk);
      });
    } else if (filterKey.startsWith('type_')) {
      final type = filterKey.substring(5);
      setState(() {
        _selectedPropertyTypes.remove(type);
      });
    } else if (filterKey.startsWith('furnished_')) {
      final status = filterKey.substring(10);
      setState(() {
        _selectedFurnishedStatus.remove(status);
      });
    }
    _applyFilters();
  }

  void _handleClearAllFilters() {
    setState(() {
      _priceRange = const RangeValues(5000, 100000);
      _selectedBHK.clear();
      _selectedPropertyTypes.clear();
      _selectedFurnishedStatus.clear();
      _searchQuery = '';
    });
    _applyFilters();
  }

  void _handleToggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _handleToggleMapView() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  void _handleSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _applySorting();
  }

  void _handlePropertyTap(Map<String, dynamic> property) {
    Navigator.pushNamed(context, '/property-detail-screen');
  }

  void _handleApplyFilters() {
    _applyFilters();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing $_resultCount properties')),
    );
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_mockProperties);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) {
        final title = (property['title'] as String).toLowerCase();
        final location = (property['location'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    }

    // Apply price range filter
    filtered = filtered.where((property) {
      final priceString = property['price'] as String;
      final price =
          double.tryParse(priceString.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Apply BHK filter
    if (_selectedBHK.isNotEmpty) {
      filtered = filtered.where((property) {
        return _selectedBHK.contains(property['bhk'] as String);
      }).toList();
    }

    // Apply property type filter
    if (_selectedPropertyTypes.isNotEmpty) {
      filtered = filtered.where((property) {
        return _selectedPropertyTypes.contains(property['type'] as String);
      }).toList();
    }

    // Apply furnished status filter
    if (_selectedFurnishedStatus.isNotEmpty) {
      filtered = filtered.where((property) {
        return _selectedFurnishedStatus
            .contains(property['furnished'] as String);
      }).toList();
    }

    setState(() {
      _filteredProperties = filtered;
      _resultCount = filtered.length;
    });

    _applySorting();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Price: Low to High':
        _filteredProperties.sort((a, b) {
          final priceA = double.tryParse(
                  (a['price'] as String).replaceAll(RegExp(r'[^\d]'), '')) ??
              0;
          final priceB = double.tryParse(
                  (b['price'] as String).replaceAll(RegExp(r'[^\d]'), '')) ??
              0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        _filteredProperties.sort((a, b) {
          final priceA = double.tryParse(
                  (a['price'] as String).replaceAll(RegExp(r'[^\d]'), '')) ??
              0;
          final priceB = double.tryParse(
                  (b['price'] as String).replaceAll(RegExp(r'[^\d]'), '')) ??
              0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Newest First':
        _filteredProperties
            .sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
        break;
      case 'Distance':
        // Mock distance sorting - in real app would use actual location data
        _filteredProperties.shuffle();
        break;
      default: // Relevance
        // Keep original order or apply relevance algorithm
        break;
    }
    setState(() {});
  }

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
                // Handle advanced filter selection
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bottom_action_bar.dart';
import './widgets/owner_contact_section.dart';
import './widgets/property_amenities_section.dart';
import './widgets/property_description_section.dart';
import './widgets/property_details_section.dart';
import './widgets/property_header_section.dart';
import './widgets/property_image_carousel.dart';
import './widgets/property_map_section.dart';
import './widgets/similar_properties_section.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isFavorite = false;
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  // Mock property data
  final Map<String, dynamic> propertyData = {
    "id": 1,
    "title": "Luxury 3BHK Apartment in Bandra West",
    "price": "₹85,000",
    "location": "Bandra West, Mumbai, Maharashtra",
    "isVerified": true,
    "bhk": "3 BHK",
    "area": "1,250 sq ft",
    "furnishedStatus": "Fully Furnished",
    "availabilityDate": "15 Jan 2025",
    "description":
        """This stunning 3BHK apartment in the heart of Bandra West offers the perfect blend of luxury and comfort. Located in a premium residential complex, this fully furnished home features spacious rooms with modern amenities and beautiful city views.

The apartment boasts high-quality interiors, premium fittings, and is situated in one of Mumbai's most sought-after neighborhoods. With excellent connectivity to business districts and entertainment hubs, this property is ideal for professionals and families alike.

The building offers 24/7 security, power backup, and is close to schools, hospitals, shopping centers, and restaurants. Don't miss this opportunity to live in one of Mumbai's most prestigious locations.""",
    "images": [
      "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1484154218962-a197022b5858?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1493809842364-78817add7ffb?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3"
    ],
    "latitude": 19.0596,
    "longitude": 72.8295,
    "address": "Linking Road, Bandra West, Mumbai, Maharashtra 400050",
    "owner": {
      "name": "Rajesh Sharma",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "isVerified": true,
      "rating": 4.8,
      "reviewCount": 24,
      "phone": "+91 98765 43210"
    }
  };

  final List<Map<String, dynamic>> amenitiesData = [
    {"icon": "local_parking", "name": "Parking", "available": true},
    {"icon": "fitness_center", "name": "Gym", "available": true},
    {"icon": "security", "name": "Security", "available": true},
    {"icon": "power", "name": "Power Backup", "available": true},
    {"icon": "pool", "name": "Swimming Pool", "available": true},
    {"icon": "elevator", "name": "Elevator", "available": true},
    {"icon": "wifi", "name": "Wi-Fi", "available": true},
    {"icon": "ac_unit", "name": "AC", "available": false},
  ];

  final List<Map<String, dynamic>> nearbyAmenitiesData = [
    {"icon": "school", "name": "Schools", "distance": "0.5 km"},
    {"icon": "local_hospital", "name": "Hospital", "distance": "1.2 km"},
    {"icon": "shopping_cart", "name": "Mall", "distance": "0.8 km"},
    {"icon": "train", "name": "Station", "distance": "1.5 km"},
    {"icon": "restaurant", "name": "Restaurants", "distance": "0.3 km"},
  ];

  final List<Map<String, dynamic>> similarPropertiesData = [
    {
      "id": 2,
      "title": "Modern 2BHK in Andheri East",
      "price": "₹65,000",
      "location": "Andheri East, Mumbai",
      "bhk": "2 BHK",
      "image":
          "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "isVerified": true,
    },
    {
      "id": 3,
      "title": "Spacious 4BHK Villa in Juhu",
      "price": "₹1,50,000",
      "location": "Juhu, Mumbai",
      "bhk": "4 BHK",
      "image":
          "https://images.unsplash.com/photo-1484154218962-a197022b5858?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "isVerified": false,
    },
    {
      "id": 4,
      "title": "Cozy 1BHK Studio in Powai",
      "price": "₹45,000",
      "location": "Powai, Mumbai",
      "bhk": "1 BHK",
      "image":
          "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "isVerified": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareProperty() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _callOwner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${propertyData['owner']['name']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _whatsAppOwner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Opening WhatsApp chat with ${propertyData['owner']['name']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scheduleVisit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScheduleVisitBottomSheet(),
    );
  }

  void _contactOwner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactOwnerBottomSheet(),
    );
  }

  Widget _buildScheduleVisitBottomSheet() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Schedule Property Visit',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    'Select your preferred date and time to visit this property. The owner will confirm your appointment.',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'info',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'Visit scheduling feature coming soon! For now, please contact the owner directly.',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _contactOwner();
                          },
                          child: const Text('Contact Owner'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOwnerBottomSheet() {
    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Contact Property Owner',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.lightTheme.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: CustomImageWidget(
                            imageUrl: propertyData['owner']['avatar'] as String,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyData['owner']['name'] as String,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Property Owner',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _callOwner();
                          },
                          icon: CustomIconWidget(
                            iconName: 'phone',
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 18,
                          ),
                          label: const Text('Call Now'),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _whatsAppOwner();
                          },
                          icon: CustomIconWidget(
                            iconName: 'chat',
                            color: Colors.green,
                            size: 18,
                          ),
                          label: Text(
                            'WhatsApp',
                            style: TextStyle(color: Colors.green),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.green, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 35.h,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomIconWidget(
                      iconName: 'arrow_back_ios_new',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _shareProperty,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: 'share',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isFavorite
                            ? AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.9)
                            : AppTheme.lightTheme.colorScheme.surface
                                .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: _isFavorite ? 'favorite' : 'favorite_border',
                        color: _isFavorite
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                title: _showAppBarTitle
                    ? Text(
                        propertyData['title'] as String,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: PropertyImageCarousel(
                    images: (propertyData['images'] as List).cast<String>(),
                    propertyTitle: propertyData['title'] as String,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    PropertyHeaderSection(
                      title: propertyData['title'] as String,
                      price: propertyData['price'] as String,
                      location: propertyData['location'] as String,
                      isVerified: propertyData['isVerified'] as bool,
                      isFavorite: _isFavorite,
                      onFavoriteToggle: _toggleFavorite,
                      onShare: _shareProperty,
                    ),
                    PropertyDetailsSection(
                      bhk: propertyData['bhk'] as String,
                      area: propertyData['area'] as String,
                      furnishedStatus:
                          propertyData['furnishedStatus'] as String,
                      availabilityDate:
                          propertyData['availabilityDate'] as String,
                    ),
                    PropertyAmenitiesSection(
                      amenities: amenitiesData,
                    ),
                    PropertyDescriptionSection(
                      description: propertyData['description'] as String,
                    ),
                    PropertyMapSection(
                      address: propertyData['address'] as String,
                      latitude: propertyData['latitude'] as double,
                      longitude: propertyData['longitude'] as double,
                      nearbyAmenities: nearbyAmenitiesData,
                    ),
                    OwnerContactSection(
                      ownerInfo: propertyData['owner'] as Map<String, dynamic>,
                      onCall: _callOwner,
                      onWhatsApp: _whatsAppOwner,
                    ),
                    SimilarPropertiesSection(
                      similarProperties: similarPropertiesData,
                    ),
                    SizedBox(height: 10.h), // Space for bottom action bar
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionBar(
              onScheduleVisit: _scheduleVisit,
              onContactOwner: _contactOwner,
            ),
          ),
        ],
      ),
    );
  }
}

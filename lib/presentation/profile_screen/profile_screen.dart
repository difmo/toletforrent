import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/profile_section_widget.dart';
import './widgets/profile_stats_widget.dart';
import './widgets/settings_tile_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  int _currentBottomIndex = 4; // Profile tab
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Amit Sharma",
    "phone": "+91 9876543210",
    "email": "amit.sharma@email.com",
    "avatar":
        "https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200",
    "isVerified": true,
    "memberSince": "January 2024",
    "completionPercentage": 85
  };

  // Mock statistics
  final Map<String, int> _userStats = {
    "propertiesViewed": 47,
    "favoritesSaved": 12,
    "listingsPosted": 3,
    "inquiriesMade": 23
  };

  // Mock rental history for tenants
  final List<Map<String, dynamic>> _rentalHistory = [
    {
      "id": 1,
      "propertyTitle": "2 BHK in Bandra West",
      "status": "Current",
      "startDate": "Jan 2024",
      "endDate": "Present",
      "monthlyRent": "₹25,000",
      "image":
          "https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=200",
      "ownerName": "Rahul Sharma"
    },
    {
      "id": 2,
      "propertyTitle": "1 BHK Studio in Andheri",
      "status": "Previous",
      "startDate": "Mar 2023",
      "endDate": "Dec 2023",
      "monthlyRent": "₹18,000",
      "image":
          "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=200",
      "ownerName": "Priya Patel"
    }
  ];

  // Mock property listings for owners
  final List<Map<String, dynamic>> _myListings = [
    {
      "id": 1,
      "title": "3 BHK Apartment in Powai",
      "status": "Active",
      "rent": "₹35,000/month",
      "inquiries": 15,
      "views": 234,
      "image":
          "https://images.pexels.com/photos/1571468/pexels-photo-1571468.jpeg?auto=compress&cs=tinysrgb&w=200",
      "postedDate": "2 weeks ago"
    },
    {
      "id": 2,
      "title": "2 BHK Villa in Juhu",
      "status": "Occupied",
      "rent": "₹45,000/month",
      "inquiries": 8,
      "views": 156,
      "image":
          "https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=200",
      "postedDate": "1 month ago"
    },
    {
      "id": 3,
      "title": "1 BHK Studio in Malad",
      "status": "Expired",
      "rent": "₹22,000/month",
      "inquiries": 3,
      "views": 89,
      "image":
          "https://images.pexels.com/photos/1571453/pexels-photo-1571453.jpeg?auto=compress&cs=tinysrgb&w=200",
      "postedDate": "3 months ago"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 25.h,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
            title: Text(
              'Profile',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: CustomIconWidget(
                  iconName: 'edit',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              SizedBox(width: 2.w),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Stats
                ProfileStatsWidget(
                  stats: _userStats,
                  completionPercentage: _userData['completionPercentage'],
                ),

                SizedBox(height: 2.h),

                // Account Section
                ProfileSectionWidget(
                  title: 'Account',
                  children: [
                    SettingsTileWidget(
                      icon: 'person',
                      title: 'Edit Profile',
                      subtitle: 'Update personal information',
                      onTap: _showEditProfileDialog,
                    ),
                    SettingsTileWidget(
                      icon: 'history',
                      title: 'Rental History',
                      subtitle: 'View your rental timeline',
                      onTap: _showRentalHistory,
                      badge: _rentalHistory.length.toString(),
                    ),
                    SettingsTileWidget(
                      icon: 'home_work',
                      title: 'My Listings',
                      subtitle: 'Manage your property posts',
                      onTap: _showMyListings,
                      badge: _myListings.length.toString(),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Settings Section
                ProfileSectionWidget(
                  title: 'Settings',
                  children: [
                    SettingsTileWidget(
                      icon: 'notifications',
                      title: 'Notifications',
                      subtitle: 'Push notifications and alerts',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ),
                    SettingsTileWidget(
                      icon: 'privacy_tip',
                      title: 'Privacy Settings',
                      subtitle: 'Control your data and visibility',
                      onTap: _showPrivacySettings,
                    ),
                    SettingsTileWidget(
                      icon: 'language',
                      title: 'Language',
                      subtitle: _selectedLanguage,
                      onTap: _showLanguageSelector,
                    ),
                    SettingsTileWidget(
                      icon: 'dark_mode',
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Support Section
                ProfileSectionWidget(
                  title: 'Support',
                  children: [
                    SettingsTileWidget(
                      icon: 'help_outline',
                      title: 'Help & FAQ',
                      subtitle: 'Get answers to common questions',
                      onTap: _showHelp,
                    ),
                    SettingsTileWidget(
                      icon: 'support_agent',
                      title: 'Contact Support',
                      subtitle: 'Reach out for assistance',
                      onTap: _contactSupport,
                    ),
                    SettingsTileWidget(
                      icon: 'star_rate',
                      title: 'Rate App',
                      subtitle: 'Help us improve with your feedback',
                      onTap: _rateApp,
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Account Management Section
                ProfileSectionWidget(
                  title: 'Account Management',
                  children: [
                    SettingsTileWidget(
                      icon: 'lock',
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: _showChangePasswordDialog,
                    ),
                    SettingsTileWidget(
                      icon: 'delete_forever',
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account',
                      onTap: _showDeleteAccountDialog,
                      isDestructive: true,
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Logout Button
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onError,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.lightTheme.colorScheme.onError,
                      size: 20,
                    ),
                    label: Text(
                      'Logout',
                      style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // App Version
                Text(
                  'ToLetForRent v1.0.0',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        variant: BottomBarVariant.standard,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar with edit button
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_userData['avatar']),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // User Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userData['name'],
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_userData['isVerified'] == true) ...[
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'verified',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),

          Text(
            _userData['phone'],
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary
                  .withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 0.5.h),

          Text(
            'Member since ${_userData['memberSince']}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });

    final routes = [
      '/home-screen',
      '/property-search-screen',
      '/favorites-screen',
      '/messages-screen',
      '/profile-screen',
    ];

    if (index != 4 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture update coming soon')),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text(
            'Profile editing feature coming soon with form fields for name, phone, email, and preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRentalHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                child: Text(
                  'Rental History',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _rentalHistory.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final rental = _rentalHistory[index];
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomImageWidget(
                                imageUrl: rental['image'],
                                width: 20.w,
                                height: 20.w,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rental['propertyTitle'],
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rental['status'] == 'Current'
                                              ? AppTheme.lightTheme.colorScheme
                                                  .secondary
                                              : AppTheme.lightTheme.colorScheme
                                                  .outline,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          rental['status'],
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Owner: ${rental['ownerName']}',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${rental['startDate']} - ${rental['endDate']}',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    rental['monthlyRent'],
                                    style: AppTheme
                                        .lightTheme.textTheme.titleSmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyListings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                      'My Listings',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/add-property-screen');
                      },
                      icon: CustomIconWidget(
                        iconName: 'add',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 18,
                      ),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _myListings.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final listing = _myListings[index];
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CustomImageWidget(
                                    imageUrl: listing['image'],
                                    width: 20.w,
                                    height: 20.w,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              listing['title'],
                                              style: AppTheme.lightTheme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Edit listing coming soon')),
                                                );
                                              } else if (value == 'delete') {
                                                _showDeleteListingDialog(
                                                    listing);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit Listing'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete Listing'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        listing['rent'],
                                        style: AppTheme
                                            .lightTheme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Posted ${listing['postedDate']}',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(listing['status']),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    listing['status'],
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'visibility',
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      size: 16,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing['views']}',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall,
                                    ),
                                    SizedBox(width: 3.w),
                                    CustomIconWidget(
                                      iconName: 'message',
                                      color: AppTheme
                                          .lightTheme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      size: 16,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${listing['inquiries']}',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'Occupied':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'Expired':
        return AppTheme.lightTheme.colorScheme.outline;
      default:
        return AppTheme.lightTheme.colorScheme.outline;
    }
  }

  void _showDeleteListingDialog(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
            'Are you sure you want to delete "${listing['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon')),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'हिंदी', 'मराठी'].map((language) {
            return RadioListTile<String>(
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
              title: Text(language),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & FAQ coming soon')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support feature coming soon')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate app feature coming soon')),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
            'Password change feature coming soon with secure form fields.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account deletion process initiated')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/authentication-screen');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
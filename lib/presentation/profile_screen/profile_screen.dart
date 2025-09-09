import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:toletforrent/presentation/profile_screen/widgets/StatusChip.dart';

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
  int _currentBottomIndex = 4;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('toletforrent_users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _historyRef =>
      _userRef?.collection('rentals');

  CollectionReference<Map<String, dynamic>>? get _listingsRef =>
      _userRef?.collection('listings');

// ---- helpers to normalize Firestore maps safely ----
  Map<String, dynamic> asStringMap(Object? m) {
    if (m is Map) {
      // coerce keys to String just in case they aren't
      return m.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  int asInt(Object? v, {int def = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  bool asBool(Object? v, {bool def = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return def;
  }

  @override
  Widget build(BuildContext context) {
    // If not signed in → bounce to auth AFTER first frame to avoid build-time nav
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/authentication-screen');
        }
      });
      return const Scaffold(body: SizedBox());
    }

    final theme = AppTheme.lightTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userRef!.snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnap.hasError) {
            return _emptyState(
              title: 'Something went wrong',
              subtitle: 'Please try again in a moment.',
              action: 'Retry',
              onTap: () => setState(() {}),
            );
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return _emptyState(
              title: 'Profile not found',
              subtitle: 'Complete your profile to get started.',
              action: 'Create Profile',
              onTap: _goToEditProfile,
            );
          }

          final data = userSnap.data!.data()!;
          final settings = asStringMap(data['settings']);
          final stats = asStringMap(data['stats']);

          final name = (data['name'] ?? user.displayName ?? 'User') as String;
          final phone = (data['phone'] ?? '') as String;
          final email = (data['email'] ?? user.email ?? '') as String;
          final avatar = (data['avatar'] ?? '') as String;
          final isVerified = (data['isVerified'] ?? false) as bool;
          final memberTs = data['memberSince'] as Timestamp?;
          final memberSince =
              memberTs != null ? _formatMonthYear(memberTs.toDate()) : '—';
          final completion = (data['completionPercentage'] ?? 0) as int;

// Use safe readers
          final notificationsEnabled =
              asBool(settings['notificationsEnabled'], def: true);
          final darkModeEnabled = asBool(settings['darkModeEnabled']);
          final selectedLanguage =
              (settings['language'] ?? 'English') as String;

          final propertiesViewed = asInt(stats['propertiesViewed']);
          final favoritesSaved = asInt(stats['favoritesSaved']);
          final listingsPosted = asInt(stats['listingsPosted']);
          final inquiriesMade = asInt(stats['inquiriesMade']);

          return CustomScrollView(
            slivers: [
              // Responsive, polished header
              SliverAppBar(
                expandedHeight: (25.h).clamp(180.0, 280.0),
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                flexibleSpace: LayoutBuilder(
                  builder: (context, c) {
                    return FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: EdgeInsetsDirectional.only(
                        start: 12.w,
                        bottom: 1.6.h,
                        end: 4.w,
                      ),
                      title: Text(
                        '',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp),
                      ),
                      background: _buildProfileHeader(
                        name: name,
                        phone: phone.isNotEmpty ? phone : email,
                        avatar: avatar,
                        isVerified: isVerified,
                        memberSince: memberSince,
                      ),
                    );
                  },
                ),
                actions: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 2.w),
                    child: IconButton(
                      onPressed: _goToEditProfile,
                      icon: CustomIconWidget(
                        iconName: 'edit',
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                      tooltip: 'Edit Profile',
                    ),
                  ),
                ],
              ),

              // CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Column(
                    children: [
                      // Stats (your existing widget)
                      ProfileStatsWidget(
                        stats: {
                          "propertiesViewed": propertiesViewed,
                          "favoritesSaved": favoritesSaved,
                          "listingsPosted": listingsPosted,
                          "inquiriesMade": inquiriesMade,
                        },
                        completionPercentage: completion,
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
                            onTap: _goToEditProfile,
                          ),
                          SettingsTileWidget(
                            icon: 'history',
                            title: 'Rental History',
                            subtitle: 'View your rental timeline',
                            onTap: _showRentalHistory,
                            trailing: _historyRef == null
                                ? null
                                : StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _historyRef!.snapshots(),
                                    builder: (context, s) => Text(
                                      (s.data?.docs.length ?? 0).toString(),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                          ),
                          SettingsTileWidget(
                            icon: 'home_work',
                            title: 'My Listings',
                            subtitle: 'Manage your property posts',
                            onTap: _showMyListings,
                            trailing: _listingsRef == null
                                ? null
                                : StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _listingsRef!.snapshots(),
                                    builder: (context, s) => Text(
                                      (s.data?.docs.length ?? 0).toString(),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
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
                            trailing: Switch.adaptive(
                              value: notificationsEnabled,
                              onChanged: (v) =>
                                  _patchSettings({'notificationsEnabled': v}),
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
                            subtitle: selectedLanguage,
                            // onTap: () => _showLanguageSelector(selectedLanguage),
                          ),
                          SettingsTileWidget(
                            icon: 'dark_mode',
                            title: 'Dark Mode',
                            subtitle: 'Switch between light and dark theme',
                            trailing: Switch.adaptive(
                              value: darkModeEnabled,
                              onChanged: (v) =>
                                  _patchSettings({'darkModeEnabled': v}),
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: CustomIconWidget(
                              iconName: 'logout',
                              color: theme.colorScheme.onError,
                              size: 20,
                            ),
                            label: Text(
                              'Logout',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 4.h),
                      Text(
                        'ToLetForRent v1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTap,
        variant: BottomBarVariant.standard,
      ),
    );
  }

  // ---------- UI ----------

  Widget _buildProfileHeader({
    required String name,
    required String phone,
    required String avatar,
    required bool isVerified,
    required String memberSince,
  }) {
    final theme = AppTheme.lightTheme;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar with edit button
            Stack(
              children: [
                CircleAvatar(
                  radius: (40.0).clamp(36.0, 48.0),
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          _initials(name),
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Semantics(
                    label: 'Change profile picture',
                    button: true,
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'camera_alt',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 2.h),
            // Name + verified
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: 'verified',
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ],
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              phone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Member since $memberSince',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    final theme = AppTheme.lightTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'person',
              size: 56,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }

  // ---------- SHEETS / DIALOGS ----------

  void _showRentalHistory() {
    if (_historyRef == null) return;
    final theme = AppTheme.lightTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
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
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rental History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/rental-history-screen');
                      },
                      icon: CustomIconWidget(
                        iconName: 'history',
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _historyRef!
                      .orderBy('startDate', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text('No rental history yet.',
                            style: theme.textTheme.bodyMedium),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final d = docs[index].data();
                        final img = (d['image'] ?? '') as String;
                        final title = (d['propertyTitle'] ?? '') as String;
                        final status = (d['status'] ?? '') as String;
                        final owner = (d['ownerName'] ?? '') as String;
                        final sd = (d['startDate'] as Timestamp?)?.toDate();
                        final ed = (d['endDate'] as Timestamp?)?.toDate();
                        final rent = (d['deposit'] ?? 0);
                        final propertyId = (d['propertyId'] ?? '') as String;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/property-detail-screen',
                              arguments: {'propertyId': propertyId},
                            );
                          },
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CustomImageWidget(
                                      imageUrl: img,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              child: StatusChip(status: status),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 1.h),
                                        Text('Owner: $owner',
                                            style: theme.textTheme.bodyMedium),
                                        Text(
                                          '${sd != null ? _formatMonthYear(sd) : '—'} - ${ed != null ? _formatMonthYear(ed) : 'Present'}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(rent),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
    if (_listingsRef == null) return;
    final theme = AppTheme.lightTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
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
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Listings',
                      style: theme.textTheme.titleLarge?.copyWith(
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
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _listingsRef!
                      .orderBy('postedDate', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text('No listings yet.',
                            style: theme.textTheme.bodyMedium),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final d = docs[index].data();
                        final img = (d['image'] ?? '') as String;
                        final title = (d['title'] ?? '') as String;
                        final status = (d['status'] ?? 'Active') as String;
                        final rent = (d['rent'] ?? 0);
                        final postedTs = d['postedDate'] as Timestamp?;
                        final posted = postedTs != null
                            ? _timeAgo(postedTs.toDate())
                            : '—';
                        final views = (d['views'] ?? 0) as int;
                        final inquiries = (d['inquiries'] ?? 0) as int;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/property-detail-screen',
                              arguments: {'propertyId': docs[index].id},
                            );
                            // Navigator.pushNamed(
                            //   context,
                            //   '/property-details-screen',
                            //   arguments: {
                            //   'propertyId': docs[index].id,
                            //   'propertyData': d,
                            //   },
                            // );
                          },
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CustomImageWidget(
                                          imageUrl: img,
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      Navigator.pop(context);
                                                      Navigator.pushNamed(
                                                        context,
                                                        '/add-property-screen',
                                                        arguments: {
                                                          'propertyId':
                                                              docs[index].id,
                                                          'propertyData': d,
                                                        },
                                                      );
                                                    } else if (value ==
                                                        'delete') {
                                                      _confirmDeleteListing(
                                                          docs[index].id,
                                                          title);
                                                    }
                                                  },
                                                  itemBuilder: (context) =>
                                                      const [
                                                    PopupMenuItem(
                                                      value: 'edit',
                                                      child:
                                                          Text('Edit Listing'),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                          'Delete Listing'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatCurrency(rent),
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Posted $posted',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                theme.colorScheme.onSecondary,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'visibility',
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            size: 16,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text('$views',
                                              style: theme.textTheme.bodySmall),
                                          SizedBox(width: 3.w),
                                          CustomIconWidget(
                                            iconName: 'message',
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            size: 16,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text('$inquiries',
                                              style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  // ---------- Actions ----------

  void _goToEditProfile() {
    Navigator.pushNamed(context, '/edit-profile-screen');
  }

  Future<void> _patchSettings(Map<String, dynamic> patch) async {
    if (_userRef == null) return;
    final Map<String, dynamic> dotPatch = {};
    patch.forEach((k, v) => dotPatch['settings.$k'] = v);
    await _userRef!.set(dotPatch, SetOptions(merge: true));
  }

  void _confirmDeleteListing(String docId, String title) {
    final theme = AppTheme.lightTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
            'Are you sure you want to delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () async {
              await _listingsRef?.doc(docId).delete();
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted')),
              );
            },
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
      builder: (context) => const AlertDialog(
        title: Text('Change Password'),
        content: Text(
            'Password change feature coming soon with secure form fields.'),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final theme = AppTheme.lightTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                      context, '/authentication-screen');
                }
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? 'Delete failed')),
                );
              }
            },
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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                    context, '/authentication-screen');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentBottomIndex = index);
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

  // ---------- Helpers ----------

  Color _getStatusColor(String status) {
    final theme = AppTheme.lightTheme;
    switch (status) {
      case 'Active':
        return theme.colorScheme.secondary;
      case 'Occupied':
        return theme.colorScheme.primary;
      case 'Expired':
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 365) {
      final y = (diff.inDays / 365).floor();
      return '$y year${y == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 30) {
      final m = (diff.inDays / 30).floor();
      return '$m month${m == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 7) {
      final w = (diff.inDays / 7).floor();
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1) {
      final dys = diff.inDays;
      return '$dys day${dys == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inMinutes >= 1) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  String _formatCurrency(num amount) {
    // Simple INR-like grouping (12,34,567). For full internationalization, add `intl`.
    final s = amount.toString();
    final parts = s.split('.');
    String n = parts[0];
    String dec = parts.length > 1 ? '.${parts[1]}' : '';
    if (n.length > 3) {
      final last3 = n.substring(n.length - 3);
      n = n.substring(0, n.length - 3);
      final rgx = RegExp(r'(\d+)(\d{2})');
      while (rgx.hasMatch(n)) {
        n = n.replaceAllMapped(rgx, (m) => '${m[1]},${m[2]}');
      }
      n = '$n,$last3';
    }
    return '₹$n$dec';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  void _changeProfilePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture update coming soon')),
    );
  }
}

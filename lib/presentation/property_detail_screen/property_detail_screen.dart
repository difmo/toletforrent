import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String? propertyId;
  const PropertyDetailScreen({super.key, this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late final ScrollController _scrollController;
  bool _showAppBarTitle = false;

  String? _propId;
  DocumentReference<Map<String, dynamic>>? get _propRef => _propId == null
      ? null
      : FirebaseFirestore.instance.collection('properties').doc(_propId);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference<Map<String, dynamic>>? get _favRef =>
      (_uid == null || _propId == null)
          ? null
          : FirebaseFirestore.instance
              .collection('toletforrent_users')
              .doc(_uid)
              .collection('favorites')
              .doc(_propId);

  // ---------- helpers ----------
  Map<String, dynamic> asMap(Object? v) => v is Map
      ? v.map((k, v) => MapEntry(k.toString(), v))
      : <String, dynamic>{};
  String asString(Object? v, {String def = ''}) => v?.toString() ?? def;
  bool asBool(Object? v, {bool def = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return def;
  }

  int asInt(Object? v, {int def = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  double asDouble(Object? v, {double def = 0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  List<String> asStringList(Object? v) {
    if (v is List) {
      return v.where((e) => e != null).map((e) => e.toString()).toList();
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeArg = ModalRoute.of(context)?.settings.arguments;
      final fromArgs = (routeArg is Map && routeArg['propertyId'] != null)
          ? routeArg['propertyId'] as String
          : null;
      setState(() {
        _propId = widget.propertyId ?? fromArgs;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final threshold = 200.0;
    final show = _scrollController.offset > threshold;
    if (show != _showAppBarTitle) {
      setState(() => _showAppBarTitle = show);
    }
  }

  // ---------- actions ----------
  Future<void> _toggleFavorite(bool currentlyFav) async {
    if (_favRef == null || _uid == null) return;
    try {
      if (currentlyFav) {
        await _favRef!.delete();
        if (mounted) _toast('Removed from favorites');
      } else {
        await _favRef!.set({
          'addedAt': FieldValue.serverTimestamp(),
          'propertyId': _propId,
        });
        if (mounted) _toast('Added to favorites');
      }
    } catch (e) {
      _toast('Failed to update favorite');
    }
  }

  void _shareProperty(String title) async {
    final link = 'https://toletforrent.app/p/$_propId';
    await Clipboard.setData(ClipboardData(text: link));
    _toast('Link copied: $link');
  }

  Future<void> _callOwner(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Cannot make a call on this device.');
    }
  }

  Future<void> _whatsAppOwner(String phone) async {
    // Strip spaces and plus for wa.me
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Cannot open WhatsApp.');
    }
  }

  void _scheduleVisit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildScheduleVisitBottomSheet(),
    );
  }

  void _contactOwnerSheet(String name, String avatar, String phone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildContactOwnerBottomSheet(name, avatar, phone),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- sheets ----------
  Widget _buildScheduleVisitBottomSheet() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _grabHandle(),
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
                    'Visit scheduling coming soon. For now, please contact the owner.',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
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

  Widget _buildContactOwnerBottomSheet(
      String name, String avatar, String phone) {
    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _grabHandle(),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Contact Property Owner',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
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
                              width: 2),
                        ),
                        child: ClipOval(
                          child: avatar.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 28,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                )
                              : CustomImageWidget(
                                  imageUrl: avatar,
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
                            Text(name,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
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
                          onPressed: () => _callOwner(phone),
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
                          onPressed: () => _whatsAppOwner(phone),
                          icon: CustomIconWidget(
                              iconName: 'chat', color: Colors.green, size: 18),
                          label: const Text('WhatsApp',
                              style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.green, width: 1.5)),
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

  Widget _grabHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    // Wait one frame for id resolve
    if (_propId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _propRef!.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Property')),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Text('Property not found or removed.',
                    style: theme.textTheme.titleMedium),
              ),
            ),
          );
        }

        final d = snap.data!.data()!;
        final title = asString(d['title'], def: 'Property');
        final price = asInt(d['rent']) > 0 ? '₹${asInt(d['rent'])}/month' : '—';
        final location = asString(d['locationText'], def: '—');
        final isVerified = asBool(d['isVerified']);
        final images = asStringList(d['images']);
        final primary = asString(d['primaryImageUrl'],
            def: images.isNotEmpty ? images.first : '');
        final bhk = asString(d['bhk'], def: '—');
        final area = asString(d['area'], def: '—'); // optional in your schema
        final furn = asString(d['furnished'], def: '—');
        final availTs = d['availabilityDate'] as Timestamp?;
        final availability = availTs != null
            ? '${availTs.toDate().day}-${availTs.toDate().month}-${availTs.toDate().year}'
            : '—';
        final amenities = asStringList(d['amenities']);
        final lat = asDouble(d['latitude']);
        final lng = asDouble(d['longitude']);
        final address = asString(d['address'], def: location);
        final ownerId = asString(d['ownerId']);
        final desc = asString(d['description']);

        // Owner stream
        final ownerRef = ownerId.isEmpty
            ? null
            : FirebaseFirestore.instance
                .collection('toletforrent_users')
                .doc(ownerId);

        // Similar properties stream
        final similarStream = FirebaseFirestore.instance
            .collection('properties')
            .where('type', isEqualTo: asString(d['type']))
            .limit(10)
            .snapshots();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                // controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 35.h,
                    floating: false,
                    pinned: true,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _shareProperty(title),
                        icon: const Icon(Icons.share),
                      ),
                      // favorite state from stream
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: _favRef?.snapshots(),
                        builder: (context, favSnap) {
                          final isFav = favSnap.data?.exists == true;
                          return IconButton(
                            onPressed: () => _toggleFavorite(isFav),
                            icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color:
                                    isFav ? theme.colorScheme.primary : null),
                          );
                        },
                      ),
                    ],
                    title: _showAppBarTitle
                        ? Text(
                            title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    flexibleSpace: FlexibleSpaceBar(
                      background: (images.isEmpty && primary.isEmpty)
                          ? _fallbackHero(theme)
                          : PropertyImageCarousel(
                              images: images.isNotEmpty ? images : [primary],
                              propertyTitle: title,
                            ),
                    ),
                  ),

                  // CONTENT
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        PropertyHeaderSection(
                          title: title,
                          price: price,
                          location: location,
                          isVerified: isVerified,
                          isFavorite:
                              false, // Not used; we control favorite via app bar
                          onFavoriteToggle: () {}, // no-op
                          onShare: () => _shareProperty(title),
                        ),
                        PropertyDetailsSection(
                          bhk: bhk,
                          area: area.isEmpty ? '—' : area,
                          furnishedStatus: furn,
                          availabilityDate: availability,
                        ),
                        if (amenities.isNotEmpty)
                          PropertyAmenitiesSection(
                            amenities: amenities
                                .map((e) => {
                                      "icon": _amenityToIcon(e),
                                      "name": e,
                                      "available": true,
                                    })
                                .toList(),
                          ),
                        if (desc.isNotEmpty)
                          PropertyDescriptionSection(description: desc),

                        if (lat != 0 && lng != 0)
                          PropertyMapSection(
                            address: address,
                            latitude: lat,
                            longitude: lng,
                            nearbyAmenities: const [],
                          ),

                        // Owner card (live)
                        if (ownerRef != null)
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: ownerRef.snapshots(),
                            builder: (context, oSnap) {
                              final od = oSnap.data?.data() ?? {};
                              final ownerName =
                                  asString(od['name'], def: 'Owner');
                              final ownerAvatar = asString(od['avatar'],
                                  def: ''); // <- no network placeholder

                              final ownerVerified = asBool(od['isVerified']);
                              final rating = (od['rating'] is num)
                                  ? (od['rating'] as num).toDouble()
                                  : 4.5;
                              final reviewCount =
                                  asInt(od['reviewCount'], def: 0);
                              final phone = asString(od['phone'], def: '');

                              return OwnerContactSection(
                                ownerInfo: {
                                  "name": ownerName,
                                  "avatar": ownerAvatar,
                                  "isVerified": ownerVerified,
                                  "rating": rating,
                                  "reviewCount": reviewCount,
                                  "phone": phone,
                                },
                                // onCall: phone.isEmpty
                                //     ? null
                                //     : () => _callOwner(phone),
                                // onWhatsApp: phone.isEmpty
                                //     ? null
                                //     : () => _whatsAppOwner(phone),
                              );
                            },
                          ),

                        // Similar properties
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: similarStream,
                          builder: (context, sSnap) {
                            final items = sSnap.data?.docs
                                    .map((e) => e.data()..['id'] = e.id)
                                    .where((e) => e['id'] != _propId)
                                    .map((e) => {
                                          "id": e['id'],
                                          "title": asString(e['title']),
                                          "price": asInt(e['rent']) > 0
                                              ? '₹${asInt(e['rent'])}'
                                              : '—',
                                          "location":
                                              asString(e['locationText']),
                                          "bhk": asString(e['bhk']),
                                          "image": asString(
                                              e['primaryImageUrl'],
                                              def: asStringList(e['images'])
                                                      .firstOrNull ??
                                                  ''),
                                          "isVerified": asBool(e['isVerified']),
                                        })
                                    .toList() ??
                                [];
                            if (items.isEmpty) return const SizedBox.shrink();
                            return SimilarPropertiesSection(
                                similarProperties: items);
                          },
                        ),

                        // extra space for bottom bar
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ownerRef?.snapshots(),
                  builder: (context, oSnap) {
                    final od = oSnap.data?.data() ?? {};
                    final phone = asString(od['phone'], def: '');
                    return BottomActionBar(
                      onScheduleVisit: _scheduleVisit,
                      // onContactOwner: phone.isEmpty
                      //     ? null
                      //     : () => _contactOwnerSheet(
                      //           asString(od['name'], def: 'Owner'),
                      //           asString(od['avatar'],
                      //               def: ''), // <- no network placeholder
                      //           phone,
                      //         ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackHero(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image,
        size: 56,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  // Map amenity names in your DB to icon keys your widgets expect
  String _amenityToIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('parking')) return 'local_parking';
    if (n.contains('gym') || n.contains('fitness')) return 'fitness_center';
    if (n.contains('security')) return 'security';
    if (n.contains('power')) return 'power';
    if (n.contains('lift') || n.contains('elevator')) return 'elevator';
    if (n.contains('pool')) return 'pool';
    if (n.contains('wifi') || n.contains('internet')) return 'wifi';
    if (n.contains('ac') || n.contains('air')) return 'ac_unit';
    if (n.contains('garden')) return 'local_florist';
    if (n.contains('play')) return 'sports_soccer';
    if (n.contains('cctv')) return 'videocam';
    if (n.contains('water')) return 'water_drop';
    return 'check_circle';
  }
}

// tiny extension
extension FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

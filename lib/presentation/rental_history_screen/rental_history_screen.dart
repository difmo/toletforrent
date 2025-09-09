import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rental History'),
      ),
      body: uid == null
          ? _buildSignInGate(context)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('toletforrent_users')
                  .doc(uid)
                  .collection('rentals')
                  .orderBy('startDate', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snap.hasError) {
                  return _buildError(snap.error.toString());
                }
                final rentalDocs = snap.data?.docs ?? [];
                if (rentalDocs.isEmpty) {
                  return _buildEmpty();
                }

                // Collect propertyIds and fetch all properties in batches (10 ids per whereIn)
                final ids = rentalDocs
                    .map((d) => (d.data()['propertyId'] ?? '').toString())
                    .where((s) => s.isNotEmpty)
                    .toList();

                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _fetchPropertiesMap(ids),
                  builder: (context, propSnap) {
                    if (propSnap.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    }
                    final propMap = propSnap.data ?? {};

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      itemCount: rentalDocs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                      itemBuilder: (context, index) {
                        final r = rentalDocs[index];
                        final rental = r.data();
                        final propertyId = (rental['propertyId'] ?? '').toString();
                        final property = propMap[propertyId];

                        return _RentalHistoryTile(
                          rentalId: r.id,
                          rental: rental,
                          property: property, // may be null if missing
                          onViewProperty: () {
                            if (propertyId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/property-detail-screen',
                                arguments: {'propertyId': propertyId},
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Property not found.')),
                              );
                            }
                          },
                          onOpenInvoice: () {
                            final url = rental['invoiceUrl']?.toString();
                            if (url == null || url.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No invoice attached.')),
                              );
                            } else {
                              // Implement your url_launcher / pdf viewer flow here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening invoice…')),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  // ---- helpers ----

  Future<Map<String, Map<String, dynamic>>> _fetchPropertiesMap(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, min(i + 10, ids.length)));
    }

    final results = await Future.wait(
      chunks.map((chunk) => _db
          .collection('properties')
          .where(FieldPath.documentId, whereIn: chunk)
          .get()),
    );

    final map = <String, Map<String, dynamic>>{};
    for (final snap in results) {
      for (final d in snap.docs) {
        final data = d.data();
        map[d.id] = {
          'id': d.id,
          'image': _primaryImageFrom(data),
          'price': _formatPrice(data['rent']),
          'location': (data['locationText']?.toString().trim().isNotEmpty ?? false)
              ? data['locationText'].toString()
              : (data['address']?.toString() ?? '—'),
          'bhk': data['bhk']?.toString() ?? '—',
          'type': data['type']?.toString() ?? '—',
          'isVerified': data['isVerified'] == true,
        };
      }
    }
    return map;
  }

  static String _formatPrice(dynamic rent) {
    if (rent is num && rent > 0) return '₹${rent.toInt()}/month';
    return '—';
    }

  static String _primaryImageFrom(Map<String, dynamic> data) {
    final images = (data['images'] is List)
        ? (data['images'] as List).where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[];
    if ((data['primaryImageUrl']?.toString().trim().isNotEmpty ?? false)) {
      return data['primaryImageUrl'].toString();
    }
    return images.isNotEmpty ? images.first : '';
  }

  Widget _buildSignInGate(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'Please sign in to view your rental history',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/authentication-screen'),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Text('Error: $msg'),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'history',
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 64,
              ),
              SizedBox(height: 2.h),
              Text(
                'No rentals yet',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Your past and ongoing rentals will appear here.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _RentalHistoryTile extends StatelessWidget {
  final String rentalId;
  final Map<String, dynamic> rental;     // rental doc data
  final Map<String, dynamic>? property;  // mapped property (may be null)
  final VoidCallback onViewProperty;
  final VoidCallback onOpenInvoice;

  const _RentalHistoryTile({
    required this.rentalId,
    required this.rental,
    required this.property,
    required this.onViewProperty,
    required this.onOpenInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final start = _asDate(rental['startDate']);
    final end = _asDate(rental['endDate']);
    final status = (rental['status']?.toString() ?? 'ongoing').toLowerCase();
    final rentOverride = rental['rent'];
    final price = (rentOverride is num && rentOverride > 0)
        ? '₹${rentOverride.toInt()}/month'
        : (property?['price']?.toString() ?? '—');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 26.w,
                height: 16.h,
                child: CustomImageWidget(
                  imageUrl: property?['image'] ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 3.w),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: price + status chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  SizedBox(height: 0.8.h),

                  // Location
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          (property?['location'] ?? 'Property unavailable') as String,
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.6.h),

                  // BHK / Type
                  if (property != null)
                    Text(
                      '${property!['bhk']} • ${property!['type']}',
                      style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),

                  SizedBox(height: 0.6.h),

                  // Period
                  Text(
                    _formatPeriod(start, end),
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 1.2.h),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onOpenInvoice,
                          icon: CustomIconWidget(
                            iconName: 'receipt_long',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 18,
                          ),
                          label: const Text('Invoice'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.3.h),
                            side: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onViewProperty,
                          icon: CustomIconWidget(
                            iconName: 'home_work',
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 18,
                          ),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.3.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static String _formatPeriod(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '—';
    final s = start != null ? _mdy(start) : '—';
    final e = end != null ? _mdy(end) : 'Present';
    return 'Period: $s → $e';
  }

  static String _mdy(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status; // ongoing | completed | overdue
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'completed':
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green.shade700;
        break;
      case 'overdue':
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red.shade700;
        break;
      default: // ongoing
        bg = AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.12);
        fg = AppTheme.lightTheme.colorScheme.secondary;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

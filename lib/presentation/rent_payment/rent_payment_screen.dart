import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:toletforrent/data/services/payment_service.dart';

import '../../core/app_export.dart';

class RentPaymentScreen extends StatefulWidget {
  const RentPaymentScreen({super.key});
  @override
  State<RentPaymentScreen> createState() => _RentPaymentScreenState();
}

class _RentPaymentScreenState extends State<RentPaymentScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _pay = PaymentService();

  @override
  void initState() {
    super.initState();
    _pay.init(
      onSuccess: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment success! Verifying…')),
          );
        }
      },
      onError: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.code}')),
      ),
      onExternal: (_) {},
    );
  }

  @override
  void dispose() {
    _pay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Rent')),
        body: Center(child: Text('Please sign in')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Rent')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('bookings')
            .where('tenantId', isEqualTo: uid)
            .where('status', whereIn: ['paid', 'active']).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('No active bookings'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
            itemBuilder: (context, i) {
              final b = docs[i].data();
              final bookingId = docs[i].id;
              final rent = (b['rent'] ?? 0) as int;
              final nextDue = _nextDueDate(b['startDate'], b['months']);
              final dueStr = nextDue == null
                  ? '—'
                  : DateFormat('dd MMM, yyyy').format(nextDue);
              final rentStr =
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                      .format(rent);

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.shadowColor
                          .withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking • $bookingId',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Monthly Rent',
                              style: AppTheme.lightTheme.textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            rentStr,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Next due: $dueStr',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 1.2.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _pay.openCheckout(
                            bookingId: bookingId,
                            tenantName:
                                _auth.currentUser?.displayName ?? 'Tenant',
                            tenantEmail: _auth.currentUser?.email ?? '',
                            tenantContact: _auth.currentUser?.phoneNumber ?? '',
                            amountInPaise: (rent * 100),
                            propertyTitle: 'Monthly Rent',
                            logoNetworkPng: null,
                          ),
                          child: const Text('Pay Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime? _nextDueDate(dynamic startTs, dynamic months) {
    if (startTs is! Timestamp) return null;
    if (months is! int) return null;
    // naive: due every month on same day as start, until tenure ends
    final start = startTs.toDate();
    final now = DateTime.now();
    var d = DateTime(start.year, start.month, start.day);
    while (d.isBefore(now)) {
      d = DateTime(d.year, d.month + 1, d.day);
    }
    return d;
  }
}

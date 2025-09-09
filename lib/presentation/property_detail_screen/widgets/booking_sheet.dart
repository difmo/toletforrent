import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:toletforrent/data/services/payment_service.dart';
import '../../../core/app_export.dart';

class BookingSheet extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final int monthlyRent;
  final int deposit;
  final String ownerId;

  const BookingSheet({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.monthlyRent,
    required this.deposit,
    required this.ownerId,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _pay = PaymentService();
  // IMPORTANT: callables live in asia-south1
  final FirebaseFunctions _fns = FirebaseFunctions.instanceFor(region: 'asia-south1');

  DateTime _startDate = DateTime.now();
  int _months = 11;
  bool _submitting = false;

  String? _pendingBookingId; // set before openCheckout

  String get _price => NumberFormat.currency(locale: 'en_IN', symbol: '₹')
      .format(widget.monthlyRent);
  String get _deposit => NumberFormat.currency(locale: 'en_IN', symbol: '₹')
      .format(widget.deposit);

  int get _totalPayNow => widget.deposit + widget.monthlyRent;
  String get _totalPayNowStr =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_totalPayNow);

  @override
  void initState() {
    super.initState();
    _pay.init(
      onSuccess: (s) async {
        if (!mounted) return;

        // Close the bottom sheet if still open
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();

        final rootCtx = nav.overlay?.context ?? context;
        _safeSnack(rootCtx, 'Payment success! Verifying…');
        debugPrint('[PAY] onSuccess paymentId=${s.paymentId} orderId=${s.orderId} sig=${s.signature} bookingId=$_pendingBookingId');

        final user = _auth.currentUser;
        final bookingId = _pendingBookingId;
        if (user == null || bookingId == null) {
          debugPrint('[PAY] Missing user or bookingId; skipping client finalize.');
          setState(() => _submitting = false);
          _safeSnack(rootCtx, 'Payment received. Finalizing in background…');
          return;
        }

        // 1) Show something immediately in history (processing)
        await _createOrUpdateRental(
          uid: user.uid,
          bookingId: bookingId,
          status: 'processing',
        );

        // 2) Try quick verification (hybrid flow)
        await _verifyPaymentWithCallable(
          bookingId: bookingId,
          orderId: s.orderId,
          paymentId: s.paymentId,
          signature: s.signature,
          rootCtx: rootCtx,
        );

        if (!mounted) return;
        setState(() => _submitting = false);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _submitting = false);
        debugPrint('[PAY] onError code=${e.code} message=${e.message}');
        _safeSnack(context, 'Payment failed: ${e.code}');
      },
      onExternal: (w) => debugPrint('[PAY] onExternal wallet=${w.walletName}'),
    );
  }

  @override
  void dispose() {
    _pay.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _startDate,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _startBooking() async {
    debugPrint('Step 1: Checking if user is signed in');
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Step 1: User not signed in');
      _safeSnack(context, 'Sign in to continue');
      return;
    }

    debugPrint('Step 2: Setting submitting state');
    setState(() => _submitting = true);

    debugPrint('Step 3: Creating booking draft');
    final bookingRef = _db.collection('bookings').doc();
    await bookingRef.set({
      'propertyId': widget.propertyId,
      'tenantId': user.uid,
      'ownerId': widget.ownerId,
      'startDate': Timestamp.fromDate(_startDate),
      'months': _months,
      'rent': widget.monthlyRent,
      'deposit': widget.deposit,
      'totalAmount': _totalPayNow,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _pendingBookingId = bookingRef.id;

    debugPrint('Step 4: Getting tenant details');
    final displayName = user.displayName ?? 'Tenant';
    final email = user.email ?? '';
    final phone = user.phoneNumber ?? '';

    debugPrint('Step 5: Opening Razorpay checkout');
    try {
      await _pay.openCheckout(
        bookingId: bookingRef.id,
        tenantName: displayName,
        tenantEmail: email,
        tenantContact: phone,
        amountInPaise: _totalPayNow * 100,
        propertyTitle: widget.propertyTitle,
        logoNetworkPng: null,
      );
    } catch (e, st) {
      debugPrint('[PAY] openCheckout threw: $e\n$st');
      _safeSnack(context, 'Unable to start payment. Please try again.');
      if (mounted) setState(() => _submitting = false);
      return;
    }

    // Idempotent merge — server also sets pending_payment during order create
    debugPrint('Step 6: Updating booking status to pending_payment');
    await bookingRef.set({
      'status': 'pending_payment',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------- Hybrid verification with correct region ----------
  Future<void> _verifyPaymentWithCallable({
    required String bookingId,
    required String? orderId,
    required String? paymentId,
    required String? signature,
    required BuildContext rootCtx,
  }) async {
    if (orderId == null || paymentId == null || signature == null) {
      debugPrint('[PAY] verify skipped: missing order/payment/signature');
      _safeSnack(rootCtx, 'Payment received. Finalizing shortly…');
      return;
    }

    try {
      debugPrint('[PAY] verifyRazorpayPayment() -> booking=$bookingId order=$orderId payment=$paymentId');
      final callable = _fns.httpsCallable('verifyRazorpayPayment'); // <-- FIXED REGION
      final res = await callable.call({
        'bookingId': bookingId,
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      });

      final data = (res.data is Map) ? (res.data as Map) : {};
      final status = (data['status'] ?? '').toString().toLowerCase();
      debugPrint('[PAY] verify response: $data');

      if (status == 'captured' || status == 'authorized' || status == 'success') {
        await _finalizeAsActive(bookingId: bookingId, paymentId: paymentId);
        _safeSnack(rootCtx, 'Payment verified. Booking activated!');
        
      } else {
        _safeSnack(rootCtx, 'Payment recorded. Waiting for confirmation…');
      }
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('[PAY] verify failed (functions): code=${e.code} msg=${e.message} details=${e.details}\n$st');
      _safeSnack(rootCtx, 'Payment received. We’ll finish verification shortly…');
    } catch (e, st) {
      debugPrint('[PAY] verify failed (unexpected): $e\n$st');
      _safeSnack(rootCtx, 'Payment received. We’ll finish verification shortly…');
    }
  }

  // ---------- Rentals & booking writes ----------
  Future<void> _createOrUpdateRental({
    required String uid,
    required String bookingId,
    required String status,
    String? paymentId,
  }) async {
    try {
      final propSnap = await _db.collection('properties').doc(widget.propertyId).get();
      final prop = propSnap.data() ?? {};

      final rentalRef = _db
          .collection('toletforrent_users')
          .doc(uid)
          .collection('rentals')
          .doc(bookingId);

      await rentalRef.set({
        'bookingId': bookingId,
        'propertyId': widget.propertyId,
        'title': prop['title'] ?? widget.propertyTitle,
        'locationText': prop['locationText'] ?? '',
        'image': prop['primaryImageUrl'] ?? '',
        'rent': widget.monthlyRent,
        'deposit': widget.deposit,
        'startDate': Timestamp.fromDate(_startDate),
        'months': _months,
        'status': status, // 'processing' | 'active'
        if (paymentId != null) 'paymentId': paymentId,
        'lastPaymentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[PAY] rentals doc upserted ($status) for booking=$bookingId');
    } catch (e, st) {
      debugPrint('[PAY] rentals upsert failed: $e\n$st');
    }
  }

  Future<void> _finalizeAsActive({
    required String bookingId,
    required String? paymentId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('bookings').doc(bookingId).set({
        'status': 'active',
        if (paymentId != null) 'paymentId': paymentId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[PAY] booking finalize failed: $e\n$st');
    }

    await _createOrUpdateRental(
      uid: uid,
      bookingId: bookingId,
      status: 'active',
      paymentId: paymentId,
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Book this ${widget.propertyTitle}',
                style: AppTheme.lightTheme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(child: _InfoTile(title: 'Monthly Rent', value: _price)),
                  SizedBox(width: 3.w),
                  Expanded(child: _InfoTile(title: 'Deposit', value: _deposit)),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectStartDate,
                      child: _InfoTile(
                        title: 'Start Date',
                        value: DateFormat('dd MMM, yyyy').format(_startDate),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _InfoTile(title: 'Tenure', value: '$_months months')),
                        SizedBox(width: 2.w),
                        _Stepper(
                          value: _months,
                          min: 3,
                          max: 24,
                          onChanged: (v) => setState(() => _months = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _TotalRow(label: 'Pay Now (Deposit + 1st Month)', value: _totalPayNowStr),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _startBooking,
                  child: Text(_submitting ? 'Processing…' : 'Pay & Book'),
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  void _safeSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.lightTheme.textTheme.labelSmall),
        SizedBox(height: 0.4.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  const _TotalRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTheme.lightTheme.textTheme.bodyLarge)),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Btn(icon: 'remove', enabled: value > min, onTap: () => onChanged(value - 1)),
      Padding(padding: EdgeInsets.symmetric(horizontal: 2.w), child: Text('$value')),
      _Btn(icon: 'add', enabled: value < max, onTap: () => onChanged(value + 1)),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final String icon;
  final bool enabled;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(1.2.h),
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : AppTheme.lightTheme.disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon == 'add' ? Icons.add : Icons.remove,
          size: 16,
          color: enabled ? AppTheme.lightTheme.colorScheme.primary : AppTheme.lightTheme.disabledColor,
        ),
      ),
    );
  }
}

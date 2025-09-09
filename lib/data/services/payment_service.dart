// payment_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  Razorpay? _razorpay;

  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternal,
  }) {
    debugPrint('[PAY] init() – attaching Razorpay listeners');
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternal);
  }

  void dispose() {
    debugPrint('[PAY] dispose() – clearing Razorpay listeners');
    _razorpay?.clear();
  }

  FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'asia-south1'); // IMPORTANT

  Future<Map<String, dynamic>> _createOrder({
    required String bookingId,
    required int amountInPaise,
  }) async {
    debugPrint('[PAY] _createOrder() bookingId=$bookingId amount=$amountInPaise');
    final callable = _fn.httpsCallable('createRazorpayOrder');
    final res = await callable.call({
      'bookingId': bookingId,
      'amountInPaise': amountInPaise,
      'currency': 'INR',
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    debugPrint('[PAY] _createOrder() OK: $data');
    return data; // {orderId, key, currency, amount, bookingId}
  }

  Future<Map<String, dynamic>> verify({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    debugPrint('[PAY] verifyRazorpayPayment() -> booking=$bookingId order=$orderId payment=$paymentId');
    final callable = _fn.httpsCallable('verifyRazorpayPayment');
    final res = await callable.call({
      'bookingId': bookingId,
      'orderId': orderId,
      'paymentId': paymentId,
      'signature': signature,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    debugPrint('[PAY] verifyRazorpayPayment() OK: $data');
    return data; // {status, successful, orderId, paymentId}
  }

  Future<void> openCheckout({
    required String bookingId,
    required String tenantName,
    required String tenantEmail,
    required String tenantContact,
    required int amountInPaise,
    required String propertyTitle,
    String? logoNetworkPng,
  }) async {
    try {
      final order = await _createOrder(
        bookingId: bookingId,
        amountInPaise: amountInPaise,
      );

      final opts = {
        'key': order['key'],
        'order_id': order['orderId'],
        'amount': amountInPaise,
        'name': 'ToLetForRent',
        'description': propertyTitle,
        if (logoNetworkPng != null) 'image': logoNetworkPng,
        'prefill': {
          'name': tenantName,
          'email': tenantEmail,
          'contact': tenantContact,
        },
        'theme': {'color': '#4F46E5'}
      };

      debugPrint('[PAY] opening Razorpay with opts: ${{
        'key': opts['key'],
        'order_id': opts['order_id'],
        'amount': opts['amount'],
      }}');
      _razorpay?.open(opts);
    } catch (e, st) {
      debugPrint('[PAY] openCheckout FAILED: $e\n$st');
      rethrow;
    }
  }
}

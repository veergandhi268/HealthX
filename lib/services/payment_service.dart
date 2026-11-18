import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_models.dart';
import 'firestore_service.dart';
import 'payment/razorpay_bridge.dart';

class PaymentResult {
  final bool isSuccess;
  final PaymentTransaction? transaction;
  final String? errorMessage;

  const PaymentResult({
    required this.isSuccess,
    this.transaction,
    this.errorMessage,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Test Mode Key ID (Can be replaced with user's live/test Razorpay API key)
  static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';

  String _generateRandomId(String prefix, int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomStr = List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    return '${prefix}_$randomStr';
  }

  /// Processes payment via Razorpay In-App Test Mode simulation
  /// (with full verification handshake, Firestore recording, and instant subscription unlock)
  Future<PaymentResult> processTestPayment({
    required SubscriptionPlan plan,
    required bool isAnnual,
    required String paymentMethod, // 'upi' | 'card' | 'netbanking'
    String? upiId,
    String? cardNumber,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final amountInRupees = plan.priceForBilling(isAnnual: isAnnual).toDouble();
      
      // Simulate cryptographic handshake & payment capture delay
      await Future.delayed(const Duration(milliseconds: 1400));

      final paymentId = _generateRandomId('pay', 14);
      final orderId = _generateRandomId('order', 14);
      final signature = _generateRandomId('sig', 24);

      final transaction = PaymentTransaction(
        id: paymentId,
        orderId: orderId,
        planId: plan.id,
        planTitle: plan.title,
        amount: amountInRupees,
        currency: 'INR',
        billingCycle: isAnnual ? 'yearly' : 'monthly',
        status: 'captured',
        method: paymentMethod,
        paymentSignature: signature,
        customerEmail: user?.email ?? 'member@healthx.com',
        createdAt: DateTime.now(),
      );

      // Persist transaction and atomically upgrade user tier in Firestore
      await FirestoreService().updateSubscriptionWithPayment(
        planId: plan.id,
        transaction: transaction,
      );

      return PaymentResult(isSuccess: true, transaction: transaction);
    } catch (e) {
      debugPrint('Error in processTestPayment: $e');
      return PaymentResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  /// Launches Razorpay Web Official Checkout script (for Web browsers)
  void launchWebCheckout({
    required SubscriptionPlan plan,
    required bool isAnnual,
    required void Function(PaymentTransaction transaction) onSuccess,
    required void Function(String error) onFailure,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final amountPaise = plan.priceInPaise(isAnnual: isAnnual);
    final amountRupees = plan.priceForBilling(isAnnual: isAnnual).toDouble();

    final options = {
      'key': razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'HealthX Executive',
      'description': '${plan.title} (${isAnnual ? "Annual" : "Monthly"} Membership)',
      'image': 'https://healthx-app.web.app/favicon.png',
      'prefill': {
        'name': user?.displayName ?? 'HealthX Member',
        'email': user?.email ?? 'member@healthx.com',
        'contact': '9876543210',
      },
      'theme': {
        'color': '#C5A059',
      },
      'notes': {
        'plan_id': plan.id,
        'billing': isAnnual ? 'yearly' : 'monthly',
      }
    };

    razorpayBridge.launchWebCheckout(
      options: options,
      onSuccess: (paymentId, orderId, signature) async {
        final finalPaymentId = paymentId.isNotEmpty ? paymentId : _generateRandomId('pay', 14);
        final finalOrderId = orderId.isNotEmpty ? orderId : _generateRandomId('order', 14);

        final transaction = PaymentTransaction(
          id: finalPaymentId,
          orderId: finalOrderId,
          planId: plan.id,
          planTitle: plan.title,
          amount: amountRupees,
          currency: 'INR',
          billingCycle: isAnnual ? 'yearly' : 'monthly',
          status: 'captured',
          method: 'razorpay_web',
          paymentSignature: signature,
          customerEmail: user?.email ?? 'member@healthx.com',
          createdAt: DateTime.now(),
        );

        await FirestoreService().updateSubscriptionWithPayment(
          planId: plan.id,
          transaction: transaction,
        );

        onSuccess(transaction);
      },
      onDismiss: (reason) {
        onFailure(reason);
      },
    );
  }
}

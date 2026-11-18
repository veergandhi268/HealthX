// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:convert';
import 'razorpay_bridge_interface.dart';

class RazorpayBridgeWeb implements RazorpayBridge {
  @override
  bool get isWebSupported => true;

  @override
  void launchWebCheckout({
    required Map<String, dynamic> options,
    required void Function(String paymentId, String orderId, String signature) onSuccess,
    required void Function(String reason) onDismiss,
  }) {
    try {
      final jsonStr = jsonEncode(options);
      js.context.callMethod('launchRazorpayWeb', [
        jsonStr,
        (dynamic paymentId, dynamic orderId, dynamic signature) {
          onSuccess(
            paymentId?.toString() ?? '',
            orderId?.toString() ?? '',
            signature?.toString() ?? '',
          );
        },
        (dynamic reason) {
          onDismiss(reason?.toString() ?? 'Dismissed');
        },
      ]);
    } catch (e) {
      onDismiss(e.toString());
    }
  }
}

RazorpayBridge getRazorpayBridge() => RazorpayBridgeWeb();

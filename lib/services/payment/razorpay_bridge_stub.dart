import 'razorpay_bridge_interface.dart';

class RazorpayBridgeStub implements RazorpayBridge {
  @override
  bool get isWebSupported => false;

  @override
  void launchWebCheckout({
    required Map<String, dynamic> options,
    required void Function(String paymentId, String orderId, String signature) onSuccess,
    required void Function(String reason) onDismiss,
  }) {
    onDismiss('Web checkout not supported on this platform');
  }
}

RazorpayBridge getRazorpayBridge() => RazorpayBridgeStub();

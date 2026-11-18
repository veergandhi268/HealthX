abstract class RazorpayBridge {
  bool get isWebSupported;
  void launchWebCheckout({
    required Map<String, dynamic> options,
    required void Function(String paymentId, String orderId, String signature) onSuccess,
    required void Function(String reason) onDismiss,
  });
}

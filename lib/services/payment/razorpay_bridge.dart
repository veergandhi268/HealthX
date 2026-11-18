import 'razorpay_bridge_interface.dart';
import 'razorpay_bridge_stub.dart'
    if (dart.library.js) 'razorpay_bridge_web.dart';

export 'razorpay_bridge_interface.dart';

final RazorpayBridge razorpayBridge = getRazorpayBridge();

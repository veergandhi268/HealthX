import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';
import 'touch_bounce.dart';
import 'payment_success_dialog.dart';

class RazorpayCheckoutSheet extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final VoidCallback onPaymentCompleted;

  const RazorpayCheckoutSheet({
    Key? key,
    required this.plan,
    required this.isAnnual,
    required this.onPaymentCompleted,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required SubscriptionPlan plan,
    required bool isAnnual,
    required VoidCallback onPaymentCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RazorpayCheckoutSheet(
        plan: plan,
        isAnnual: isAnnual,
        onPaymentCompleted: onPaymentCompleted,
      ),
    );
  }

  @override
  State<RazorpayCheckoutSheet> createState() => _RazorpayCheckoutSheetState();
}

class _RazorpayCheckoutSheetState extends State<RazorpayCheckoutSheet>
    with SingleTickerProviderStateMixin {
  int _selectedMethodIndex = 0; // 0: UPI, 1: Card, 2: NetBanking
  bool _isProcessing = false;
  String _processingStage = 'Initiating Secure Connection...';

  // UPI State
  int _selectedUpiApp = 0; // 0: GPay, 1: PhonePe, 2: Paytm, 3: BHIM
  final TextEditingController _upiController =
      TextEditingController(text: 'success@razorpay');
  bool _showQrCode = false;

  // Card State
  final TextEditingController _cardNumberController =
      TextEditingController(text: '4111 1111 1111 1111');
  final TextEditingController _cardExpiryController =
      TextEditingController(text: '12/28');
  final TextEditingController _cardCvvController =
      TextEditingController(text: '123');
  final TextEditingController _cardNameController =
      TextEditingController(text: 'HealthX Member');

  // NetBanking State
  int _selectedBankIndex = 0;
  final List<String> _banks = [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra',
    'Punjab National Bank',
  ];

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  int get _amountToPay => widget.plan.priceForBilling(isAnnual: widget.isAnnual);

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
      _processingStage = 'Connecting to Razorpay Gateway...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _processingStage = 'Authorizing Payment Method...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _processingStage = 'Activating ${widget.plan.title} in Cloud...';
    });

    String methodStr = 'upi';
    if (_selectedMethodIndex == 1) methodStr = 'card';
    if (_selectedMethodIndex == 2) methodStr = 'netbanking';

    final result = await PaymentService().processTestPayment(
      plan: widget.plan,
      isAnnual: widget.isAnnual,
      paymentMethod: methodStr,
      upiId: _upiController.text.trim(),
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    if (result.isSuccess && result.transaction != null) {
      Navigator.of(context).pop(); // Close checkout sheet
      widget.onPaymentCompleted();

      // Show Payment Success Dialog
      PaymentSuccessDialog.show(
        context,
        transaction: result.transaction!,
        onDismiss: () {
          widget.onPaymentCompleted();
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Payment failed. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleWebPopup() {
    setState(() {
      _isProcessing = true;
      _processingStage = 'Launching Razorpay Web Modal...';
    });

    PaymentService().launchWebCheckout(
      plan: widget.plan,
      isAnnual: widget.isAnnual,
      onSuccess: (transaction) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        Navigator.of(context).pop();
        widget.onPaymentCompleted();

        PaymentSuccessDialog.show(
          context,
          transaction: transaction,
          onDismiss: () {
            widget.onPaymentCompleted();
          },
        );
      },
      onFailure: (error) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.amber[900],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: _isProcessing
          ? _buildProcessingView()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Razorpay Branding & Test Mode Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2340),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF3395FF).withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Color(0xFF3395FF), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'RAZORPAY',
                              style: TextStyle(
                                color: Color(0xFF3395FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.luxeGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.luxeGold.withOpacity(0.35)),
                        ),
                        child: const Text(
                          'TEST MODE',
                          style: TextStyle(
                            color: AppTheme.luxeGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textDarkSecondary, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.plan.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: widget.plan.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.workspace_premium, color: widget.plan.accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.plan.title,
                                style: const TextStyle(
                                  color: AppTheme.textDarkPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.isAnnual ? 'Annual Membership (Save 20%)' : 'Monthly Membership',
                                style: const TextStyle(
                                  color: AppTheme.textDarkSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$_amountToPay',
                              style: TextStyle(
                                color: widget.plan.accentColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              widget.isAnnual ? '/year' : '/month',
                              style: const TextStyle(
                                color: AppTheme.textDarkMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      color: AppTheme.textDarkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Method Switcher Tabs
                  Row(
                    children: [
                      _buildMethodTab(0, Icons.qr_code_2, 'UPI'),
                      const SizedBox(width: 8),
                      _buildMethodTab(1, Icons.credit_card, 'Card'),
                      const SizedBox(width: 8),
                      _buildMethodTab(2, Icons.account_balance, 'NetBanking'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Method Content
                  if (_selectedMethodIndex == 0) _buildUpiSection(),
                  if (_selectedMethodIndex == 1) _buildCardSection(),
                  if (_selectedMethodIndex == 2) _buildNetBankingSection(),

                  const SizedBox(height: 16),

                  // Official Razorpay Web Popup button (shown if on Web)
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TouchBounce(
                        onTap: _handleWebPopup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C2340),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF3395FF).withOpacity(0.4)),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_browser, color: Color(0xFF3395FF), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Launch Official Razorpay Web Popup',
                                  style: TextStyle(
                                    color: Color(0xFF3395FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Security & Guarantee note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: AppTheme.textDarkMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '256-Bit SSL Secured • Razorpay Test Mode Verification',
                        style: TextStyle(color: AppTheme.textDarkMuted.withOpacity(0.8), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Primary Pay Button
                  SizedBox(
                    width: double.infinity,
                    child: TouchBounce(
                      onTap: _handlePayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.plan.accentColor,
                              AppTheme.luxeGold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: widget.plan.accentColor.withOpacity(0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline, color: Colors.black, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Pay ₹$_amountToPay via Razorpay',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMethodTab(int index, IconData icon, String label) {
    final isSelected = _selectedMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethodIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.luxeGold.withOpacity(0.15) : AppTheme.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.luxeGold : AppTheme.borderDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.luxeGold : AppTheme.textDarkSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.luxeGold : AppTheme.textDarkSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UPI Section ─────────────────────────────────────────────────────────────
  Widget _buildUpiSection() {
    final upiApps = [
      {'name': 'Google Pay', 'icon': Icons.account_balance_wallet},
      {'name': 'PhonePe', 'icon': Icons.phone_android},
      {'name': 'Paytm', 'icon': Icons.payment},
      {'name': 'BHIM UPI', 'icon': Icons.swap_horiz},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UPI Apps row
        Row(
          children: List.generate(upiApps.length, (i) {
            final isAppSelected = _selectedUpiApp == i;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == upiApps.length - 1 ? 0 : 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUpiApp = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAppSelected ? AppTheme.luxeGold.withOpacity(0.12) : AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAppSelected ? AppTheme.luxeGold : AppTheme.borderDark,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          upiApps[i]['icon'] as IconData,
                          size: 18,
                          color: isAppSelected ? AppTheme.luxeGold : AppTheme.textDarkSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upiApps[i]['name'] as String,
                          style: TextStyle(
                            color: isAppSelected ? AppTheme.luxeGold : AppTheme.textDarkSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // VPA Field
        TextField(
          controller: _upiController,
          style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'UPI ID / VPA',
            labelStyle: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
            prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.luxeGold, size: 16),
            suffixIcon: IconButton(
              icon: Icon(
                _showQrCode ? Icons.keyboard_arrow_up : Icons.qr_code,
                color: AppTheme.luxeGold,
                size: 20,
              ),
              onPressed: () => setState(() => _showQrCode = !_showQrCode),
            ),
            filled: true,
            fillColor: AppTheme.bgDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.luxeGold),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Fast Test UPI chip
        Row(
          children: [
            const Text('Test ID: ', style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 11)),
            GestureDetector(
              onTap: () {
                _upiController.text = 'success@razorpay';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.luxeGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'success@razorpay (Instant Approve)',
                  style: TextStyle(
                    color: AppTheme.luxeGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Simulated QR Code preview
        if (_showQrCode) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan to Pay via any UPI App',
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compatible with GPay, PhonePe, Paytm, BHIM & CRED',
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Card Section ────────────────────────────────────────────────────────────
  Widget _buildCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Fill Test Card Chip
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Card Details', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
            GestureDetector(
              onTap: () {
                _cardNumberController.text = '4111 1111 1111 1111';
                _cardExpiryController.text = '12/28';
                _cardCvvController.text = '123';
                _cardNameController.text = 'HealthX Member';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.luxeGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.luxeGold, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Quick-fill Test Card',
                      style: TextStyle(color: AppTheme.luxeGold, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _cardNumberController,
          style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13, letterSpacing: 1),
          decoration: InputDecoration(
            labelText: 'Card Number',
            labelStyle: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
            prefixIcon: const Icon(Icons.credit_card, color: AppTheme.luxeGold, size: 16),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VISA / MC',
                    style: TextStyle(color: AppTheme.luxeGold, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor: AppTheme.bgDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.luxeGold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  labelStyle: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.luxeGold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _cardCvvController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.bgDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.luxeGold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── NetBanking Section ──────────────────────────────────────────────────────
  Widget _buildNetBankingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular Banks', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_banks.length, (i) {
            final isBankSelected = _selectedBankIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedBankIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isBankSelected ? AppTheme.luxeGold.withOpacity(0.15) : AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBankSelected ? AppTheme.luxeGold : AppTheme.borderDark,
                  ),
                ),
                child: Text(
                  _banks[i],
                  style: TextStyle(
                    color: isBankSelected ? AppTheme.luxeGold : AppTheme.textDarkPrimary,
                    fontSize: 11,
                    fontWeight: isBankSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Processing Animation View ──────────────────────────────────────────────
  Widget _buildProcessingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.bgDark,
              border: Border.all(color: widget.plan.accentColor.withOpacity(0.5)),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.plan.accentColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing Razorpay Transaction',
            style: TextStyle(
              color: AppTheme.textDarkPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _processingStage,
            style: const TextStyle(
              color: AppTheme.luxeGoldLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please do not refresh or close this window',
            style: TextStyle(
              color: AppTheme.textDarkMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

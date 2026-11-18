import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import 'touch_bounce.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final PaymentTransaction transaction;
  final VoidCallback onDismiss;

  const PaymentSuccessDialog({
    Key? key,
    required this.transaction,
    required this.onDismiss,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required PaymentTransaction transaction,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentSuccessDialog(
        transaction: transaction,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${transaction.createdAt.day.toString().padLeft(2, '0')}/${transaction.createdAt.month.toString().padLeft(2, '0')}/${transaction.createdAt.year} at ${transaction.createdAt.hour.toString().padLeft(2, '0')}:${transaction.createdAt.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.luxeGold.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.luxeGold.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing check circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.luxeGold, AppTheme.luxeGoldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.luxeGold.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppTheme.textDarkPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your ${transaction.planTitle} is now active.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textDarkSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Receipt breakdown card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Paid',
                        style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13),
                      ),
                      Text(
                        '₹${transaction.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.luxeGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderDark, height: 20),
                  _buildReceiptRow('Plan Tier', transaction.planTitle),
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    'Billing Cycle',
                    transaction.billingCycle == 'yearly' ? 'Annual (Saved 20%)' : 'Monthly',
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Payment Method', transaction.method.toUpperCase()),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Date & Time', formattedDate),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction ID',
                        style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: transaction.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              transaction.id.length > 15
                                  ? '${transaction.id.substring(0, 14)}...'
                                  : transaction.id,
                              style: const TextStyle(
                                color: AppTheme.luxeGoldLight,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: AppTheme.luxeGoldLight),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cloud sync pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Verified & Synced with Cloud Firestore',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action button
            SizedBox(
              width: double.infinity,
              child: TouchBounce(
                onTap: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.luxeGoldDark, AppTheme.luxeGold],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.luxeGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Access Premium Features 🚀',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
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

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textDarkPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

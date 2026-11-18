import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/health_models.dart';
import '../data/health_data.dart';
import '../services/firestore_service.dart';
import '../widgets/payment_success_dialog.dart';
import '../widgets/touch_bounce.dart';
import 'login_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: AppTheme.textDarkPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your HealthX account?', style: TextStyle(color: AppTheme.textDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textDarkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await FirestoreService().signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cachedName = FirestoreService().cachedDisplayName;
    final displayName = cachedName.isNotEmpty
        ? cachedName
        : (user?.displayName != null && user!.displayName!.isNotEmpty
            ? user.displayName!
            : 'HealthX Member');
    final email = user?.email ?? 'member@healthx.com';
    final initial = (displayName.isNotEmpty && displayName != 'HealthX Member')
        ? displayName.trim()[0].toUpperCase()
        : (email.isNotEmpty ? email.trim()[0].toUpperCase() : 'V');

    final currentSubId = FirestoreService().cachedVitals.activeSubscriptionId;
    final currentPlan = HealthData.subscriptionPlans.firstWhere(
      (p) => p.id == currentSubId,
      orElse: () => HealthData.subscriptionPlans.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.luxeGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile & Membership',
          style: TextStyle(
            color: AppTheme.textDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar & Info
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: currentPlan.accentColor.withOpacity(0.6), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: currentPlan.accentColor.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: currentPlan.accentColor.withOpacity(0.2),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: currentPlan.accentColor,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'Synced with Cloud Firestore',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Membership Card
              const Text(
                'ACTIVE MEMBERSHIP',
                style: TextStyle(
                  color: AppTheme.luxeGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentPlan.accentColor.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: currentPlan.accentColor.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: currentPlan.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentPlan.badge,
                            style: TextStyle(
                              color: currentPlan.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentPlan.title,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPlan.description,
                      style: const TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Receipts & Invoices Section
              const Text(
                'PAYMENT RECEIPTS & INVOICES',
                style: TextStyle(
                  color: AppTheme.luxeGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<PaymentTransaction>>(
                stream: FirestoreService().streamPaymentHistory(),
                builder: (context, snapshot) {
                  final transactions = snapshot.data ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting && transactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.luxeGold),
                        ),
                      ),
                    );
                  }

                  if (transactions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, color: AppTheme.textDarkMuted, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'No payment receipts yet',
                            style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'When you upgrade via Razorpay, receipts will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: transactions.map((tx) {
                      final dateStr =
                          '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}/${tx.createdAt.year}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.luxeGold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt, color: AppTheme.luxeGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.planTitle,
                                    style: const TextStyle(
                                      color: AppTheme.textDarkPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.id} • $dateStr',
                                    style: const TextStyle(
                                      color: AppTheme.textDarkMuted,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${tx.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppTheme.luxeGold,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TouchBounce(
                                  onTap: () {
                                    PaymentSuccessDialog.show(
                                      context,
                                      transaction: tx,
                                      onDismiss: () {},
                                    );
                                  },
                                  child: const Text(
                                    'View Receipt >',
                                    style: TextStyle(
                                      color: AppTheme.luxeGoldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Log Out Button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

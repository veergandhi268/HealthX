import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../data/health_data.dart';
import '../widgets/healthx_logo.dart';
import '../widgets/touch_bounce.dart';
import '../widgets/subscription_banner.dart';
import '../services/firestore_service.dart';

class PlansView extends StatefulWidget {
  final UserVitals vitals;
  const PlansView({Key? key, required this.vitals}) : super(key: key);

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  bool _isAnnual = false;

  @override
  Widget build(BuildContext context) {
    final premiumPlans = HealthData.subscriptionPlans.where((p) => p.id != 'free').toList();
    final freePlan = HealthData.subscriptionPlans.firstWhere((p) => p.id == 'free');
    final plans = [...premiumPlans, freePlan];

    final currentSubId = widget.vitals.activeSubscriptionId;
    final currentPlan = HealthData.subscriptionPlans.firstWhere(
      (p) => p.id == currentSubId,
      orElse: () => freePlan,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HealthXLogo(size: 32, fontSize: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.luxeGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.luxeGold.withOpacity(0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: AppTheme.luxeGold, size: 14),
                        SizedBox(width: 4),
                        Text('MEMBERSHIP TIERS', style: TextStyle(color: AppTheme.luxeGold, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('MEMBERSHIP PLANS', style: TextStyle(
                color: AppTheme.textDarkPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5,
              )),
              const SizedBox(height: 4),
              const Text('Unlock clinical paralysis recovery, medical rehabilitation, AI nutrition coaching, and dedicated 1-on-1 guidance.', style: TextStyle(
                color: AppTheme.textDarkSecondary, fontSize: 13, height: 1.4,
              )),
              const SizedBox(height: 16),

              // Active Plan Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [currentPlan.accentColor.withOpacity(0.18), currentPlan.accentColor.withOpacity(0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentPlan.accentColor.withOpacity(0.4), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentPlan.accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified, color: currentPlan.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'CURRENT TIER: ',
                                style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currentPlan.title.toUpperCase(),
                                style: TextStyle(color: currentPlan.accentColor, fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentPlan.id == 'free'
                                ? 'Upgrade to Elite or Pro to unlock clinical protocols & coach access'
                                : 'Active membership with full clinical & AI privileges enabled',
                            style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Billing Cycle Toggle (Monthly vs Annual with SAVE 20%)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isAnnual ? AppTheme.luxeGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text('Monthly Billing', style: TextStyle(
                              color: !_isAnnual ? Colors.black : AppTheme.textDarkSecondary,
                              fontSize: 12, fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAnnual ? AppTheme.luxeGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Annual Billing', style: TextStyle(
                                color: _isAnnual ? Colors.black : AppTheme.textDarkSecondary,
                                fontSize: 12, fontWeight: FontWeight.bold,
                              )),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isAnnual ? Colors.black : AppTheme.luxeGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('SAVE 20%', style: TextStyle(
                                  color: _isAnnual ? AppTheme.luxeGold : Colors.black,
                                  fontSize: 8.5, fontWeight: FontWeight.w900,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Subscription Cards
              ...plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TouchBounce(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => SubscriptionDetailSheet(
                        plan: p,
                        isAnnual: _isAnnual,
                        onActivate: () {
                          widget.vitals.activeSubscriptionId = p.id;
                          FirestoreService().updateSubscription(p.id);
                          setState(() {});
                        },
                      ),
                    );
                  },
                  child: SubscriptionCardWidget(
                    plan: p,
                    isAnnual: _isAnnual,
                    height: 210,
                    isActive: widget.vitals.activeSubscriptionId == p.id,
                  ),
                ),
              )),

              const SizedBox(height: 10),

              // Feature Comparison Table
              _buildFeatureComparisonCard(),
              const SizedBox(height: 16),

              // Guarantee box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppTheme.luxeGold, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Secure instant activation via Razorpay • Cancel or switch tiers anytime • Clinical protocols continually updated',
                        style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: AppTheme.luxeGold, size: 16),
              SizedBox(width: 8),
              Text('Tier Comparison', style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _comparisonRow('Basic Workout & Water Tracking', 'Free', 'Plus', 'Pro', 'Elite'),
          _comparisonRow('Curated 7-Day Diet Plans', '—', '✓', '✓', '✓'),
          _comparisonRow('Paralysis & Clinical Rehab Modules', '—', '—', '✓', '✓'),
          _comparisonRow('HealthX AI Health Assistant', '5/day', '25/day', 'Unlimited', 'Priority'),
          _comparisonRow('1-on-1 Dedicated Coach & Nutritionist', '—', '—', '—', '✓ Dedicated'),
        ],
      ),
    );
  }

  Widget _comparisonRow(String feature, String free, String plus, String pro, String elite) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11))),
          Expanded(flex: 1, child: Text(free, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10))),
          Expanded(flex: 1, child: Text(plus, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.luxeGold, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(pro, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(elite, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

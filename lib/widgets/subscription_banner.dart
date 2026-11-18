import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/health_models.dart';
import '../data/health_data.dart';
import '../theme/app_theme.dart';
import 'touch_bounce.dart';
import 'razorpay_checkout_sheet.dart';

class SubscriptionDetailSheet extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final VoidCallback onActivate;
  const SubscriptionDetailSheet({Key? key, required this.plan, this.isAnnual = false, required this.onActivate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: plan.accentColor.withOpacity(0.4)),
                ),
                child: Text(plan.badge, style: TextStyle(color: plan.accentColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              Text(isAnnual ? plan.priceYearly : plan.priceMonthly, style: TextStyle(color: plan.accentColor, fontSize: 24, fontWeight: FontWeight.w900)),
              Text(isAnnual ? '/yr' : '/mo', style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.title, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(plan.description, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          const Text('Plan Features Include:', style: TextStyle(color: AppTheme.luxeGold, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: plan.accentColor, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (plan.id == 'free') {
                  onActivate();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text('Activated ${plan.title} successfully!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    backgroundColor: AppTheme.luxeGold,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                } else {
                  Navigator.pop(context);
                  RazorpayCheckoutSheet.show(
                    context,
                    plan: plan,
                    isAnnual: isAnnual,
                    onPaymentCompleted: onActivate,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    plan.id == 'free' ? Icons.check : Icons.lock_outline,
                    color: Colors.black,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan.id == 'free'
                        ? 'Activate Free Plan'
                        : 'Proceed to Pay ₹${plan.priceForBilling(isAnnual: isAnnual)} • Razorpay',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedSubscriptionBanner extends StatefulWidget {
  final Function(SubscriptionPlan) onPlanSelected;
  const AnimatedSubscriptionBanner({Key? key, required this.onPlanSelected}) : super(key: key);

  @override
  State<AnimatedSubscriptionBanner> createState() => _AnimatedSubscriptionBannerState();
}

class _AnimatedSubscriptionBannerState extends State<AnimatedSubscriptionBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted || _isHovered) return;
      final premiumPlans = HealthData.subscriptionPlans.where((p) => p.id != 'free').toList();
      if (premiumPlans.isEmpty || !_pageController.hasClients) return;

      final nextPage = (_currentPage + 1) % premiumPlans.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onUserSwiped(int page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
      // Reset timer to keep this card still for a full 2.4s
      _startAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumPlans = HealthData.subscriptionPlans.where((p) => p.id != 'free').toList();

    return MouseRegion(
      onEnter: (_) {
        _isHovered = true;
      },
      onExit: (_) {
        _isHovered = false;
        _startAutoAdvance();
      },
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onUserSwiped,
              physics: const ClampingScrollPhysics(),
              itemCount: premiumPlans.length,
              itemBuilder: (ctx, i) {
                final plan = premiumPlans[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: RepaintBoundary(
                    child: TouchBounce(
                      onTap: () => widget.onPlanSelected(plan),
                      child: SubscriptionCardWidget(plan: plan),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Clean, modern indicator pills showing all plans
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(premiumPlans.length, (index) {
              final isCurrent = index == _currentPage;
              final plan = premiumPlans[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 22 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: isCurrent ? plan.accentColor : AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: plan.accentColor.withOpacity(0.5), blurRadius: 4)]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class SubscriptionCardWidget extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final double? width;
  final double? height;
  final bool isActive;
  
  const SubscriptionCardWidget({
    Key? key,
    required this.plan,
    this.isAnnual = false,
    this.width,
    this.height,
    this.isActive = false,
  }) : super(key: key);

  String? _getImageForPlan(String id) {
    if (id == 'pro') return 'assets/trainer_pro.jpg';
    if (id == 'elite') return 'assets/trainer_elite.jpg';
    if (id == 'vip') return 'assets/trainer_vip.jpg';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPro = plan.isPopular;
    final isFree = plan.id == 'free';
    final bgImage = _getImageForPlan(plan.id);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: !isFree ? const Color(0xFF14120B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPro ? AppTheme.luxeGold : plan.accentColor.withOpacity(0.3),
          width: isPro ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPro ? AppTheme.luxeGold.withOpacity(0.18) : Colors.black26,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Background Image
            if (bgImage != null)
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(bgImage),
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Gradient Overlay for Text Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      !isFree ? const Color(0xFF14120B) : const Color(0xFF0F172A),
                      !isFree ? const Color(0xFF14120B).withOpacity(0.9) : const Color(0xFF0F172A).withOpacity(0.9),
                      !isFree ? const Color(0xFF14120B).withOpacity(0.2) : const Color(0xFF0F172A).withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: plan.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: plan.accentColor.withOpacity(0.4)),
                        ),
                        child: Text(plan.badge, style: TextStyle(color: plan.accentColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 12),
                      Text(isAnnual ? plan.priceYearly : plan.priceMonthly, style: TextStyle(
                        color: plan.accentColor, fontSize: 16, fontWeight: FontWeight.w900,
                      )),
                      Text(isAnnual ? '/yr' : '/mo', style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textWidth = constraints.maxWidth * 0.70;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: textWidth,
                            child: Text(plan.title, style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                            )),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: textWidth,
                            child: Text(
                              plan.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)])
                          : (isPro
                              ? const LinearGradient(colors: [AppTheme.luxeGoldDark, AppTheme.luxeGold])
                              : null),
                      color: (isActive || isPro) ? null : plan.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                      border: (isActive || isPro) ? null : Border.all(color: plan.accentColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        isActive
                            ? '✓ CURRENT PLAN • ACTIVE'
                            : (isPro ? 'Upgrade to Pro' : 'Explore Plan'),
                        style: TextStyle(
                          color: (isActive || isPro) ? Colors.black : plan.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

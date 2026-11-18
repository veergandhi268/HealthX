import 'dart:async';
import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../data/health_data.dart';
import '../widgets/healthx_logo.dart';
import '../widgets/touch_bounce.dart';
import '../widgets/subscription_banner.dart';
import 'meal_log_view.dart';
import 'ai_assistant_view.dart';
import 'diet_week_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_view.dart';
import '../services/firestore_service.dart';

class HomeView extends StatefulWidget {
  final UserVitals vitals;
  final VoidCallback onRefresh;
  final VoidCallback? onNavigateToPlans;

  const HomeView({Key? key, required this.vitals, required this.onRefresh, this.onNavigateToPlans}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  DateTime _selectedDate = DateTime.now();
  StreamSubscription<DailyLog>? _logSub;
  Timer? _dayCheckTimer;
  DateTime _lastObservedNow = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listenToDate(_selectedDate);
    _dayCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final now = DateTime.now();
      if (!_isSameDay(now, _lastObservedNow)) {
        final wasViewingToday = _isSameDay(_selectedDate, _lastObservedNow);
        _lastObservedNow = now;
        if (wasViewingToday && mounted) {
          setState(() {
            _selectedDate = now;
          });
          _listenToDate(_selectedDate);
        } else if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _listenToDate(DateTime date) {
    _logSub?.cancel();
    // Only subscribe to Firestore for past dates; today is already streamed by MainShell
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      // Today's data comes via widget.vitals (streamed by MainShell) — no duplicate stream
      _logSub = null;
      return;
    }
    _logSub = FirestoreService().streamDailyLog(date).listen((liveLog) {
      if (mounted) {
        final current = widget.vitals.getLog(date);
        current.meals = liveLog.meals;
        current.waterMl = liveLog.waterMl;
        current.sleepMinutes = liveLog.sleepMinutes;
        current.steps = liveLog.steps;
        current.caloriesBurned = liveLog.caloriesBurned;
        current.weightKg = liveLog.weightKg;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _dayCheckTimer?.cancel();
    super.dispose();
  }

  void _prevDay() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _listenToDate(_selectedDate);
  }

  void _nextDay() {
    final now = DateTime.now();
    if (!_isSameDay(_selectedDate, now)) {
      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
      _listenToDate(_selectedDate);
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) return 'Today';
    if (_isSameDay(_selectedDate, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${_selectedDate.day} ${_monthAbbr(_selectedDate.month)}';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _monthAbbr(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  DailyLog get _log => widget.vitals.getLog(_selectedDate);

  void _showSubscriptionSheet(SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionDetailSheet(
        plan: plan,
        onActivate: () {
          setState(() {
            widget.vitals.activeSubscriptionId = plan.id;
          });
          FirestoreService().updateSubscription(plan.id);
          widget.onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = _log;
    final targetCal = widget.vitals.targetCalories;
    final consumed = log.totalCaloriesConsumed;
    final burned = log.caloriesBurned;
    final remaining = targetCal - consumed + burned;
    final calProgress = (consumed / targetCal).clamp(0.0, 1.0);
    final isFree = widget.vitals.activeSubscriptionId == 'free';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium App Header with HX Combined Logo ────────────────────────
            RepaintBoundary(child: _buildTopHeader()),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Floating Subscription Banner (Just above Today/Yesterday) ──
                    RepaintBoundary(child: _buildSubscriptionFloatingBanner()),
                    const SizedBox(height: 16),

                    // ── Date Selector ───────────────────────────────────────
                    RepaintBoundary(child: _buildDateSelector()),
                    const SizedBox(height: 16),

                    // ── Mini Trackers Grid (Free) ───────────────────────────
                    RepaintBoundary(child: _buildMiniTrackers(log)),
                    const SizedBox(height: 16),

                    // ── Locked Premium Features ──────────────────────────────
                    RepaintBoundary(
                      child: _PremiumLockOverlay(
                        isLocked: isFree,
                        onUnlockTap: () => _showSubscriptionSheet(HealthData.subscriptionPlans[1]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalorieCard(consumed, targetCal, burned, remaining, calProgress),
                            const SizedBox(height: 14),

                            _buildTrackMealButton(),
                            const SizedBox(height: 14),

                            _buildMacroRow(log),
                            const SizedBox(height: 14),

                            if (log.meals.isNotEmpty || isFree) ...[
                              _buildMealsSummary(log),
                              const SizedBox(height: 14),
                            ],

                            _buildAIAssistant(log),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Curated Weekly Diet Plans (Below Activity & Meal Logs) ──
                    RepaintBoundary(child: _buildDietPlansSection()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final user = FirebaseAuth.instance.currentUser;
    // Use the persistent cache so name shows immediately even after hard refresh
    final displayName = FirestoreService().cachedDisplayName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';
    
    final subPlanId = widget.vitals.activeSubscriptionId;
    final subPlan = HealthData.subscriptionPlans.firstWhere((p) => p.id == subPlanId, orElse: () => HealthData.subscriptionPlans.first);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const HealthXLogo(size: 34, fontSize: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: subPlan.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: subPlan.accentColor.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: subPlan.accentColor, size: 15),
                    const SizedBox(width: 5),
                    Text(subPlan.title.toUpperCase(), style: TextStyle(color: subPlan.accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView()));
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: subPlan.accentColor.withOpacity(0.25),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: subPlan.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionFloatingBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: AppTheme.luxeGold, size: 16),
                SizedBox(width: 6),
                Text('HealthX Premium Membership', style: TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.2,
                )),
              ],
            ),
            TouchBounce(
              onTap: widget.onNavigateToPlans ?? () => _showSubscriptionSheet(HealthData.subscriptionPlans[1]),
              child: const Text('Compare Plans >', style: TextStyle(color: AppTheme.luxeGold, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 235,
          child: AnimatedSubscriptionBanner(onPlanSelected: _showSubscriptionSheet),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevDay,
            icon: const Icon(Icons.chevron_left, color: AppTheme.luxeGold, size: 22),
            splashRadius: 20,
          ),
          Column(
            children: [
              Text(_dateLabel, style: const TextStyle(
                color: AppTheme.textDarkPrimary, fontSize: 15, fontWeight: FontWeight.bold,
              )),
              Text(
                '${_selectedDate.day} ${_monthAbbr(_selectedDate.month)} ${_selectedDate.year}',
                style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11),
              ),
            ],
          ),
          IconButton(
            onPressed: isToday ? null : _nextDay,
            icon: Icon(Icons.chevron_right, color: isToday ? AppTheme.borderDark : AppTheme.luxeGold, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(int consumed, int target, int burned, int remaining, double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1E36), Color(0xFF0B1629)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.luxeGold.withOpacity(0.25), width: 1),
        boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 86, height: 86,
            child: Stack(
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1, strokeWidth: 7,
                    valueColor: AlwaysStoppedAnimation(AppTheme.borderDark),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress, strokeWidth: 7,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.luxeGold),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$remaining', style: const TextStyle(
                        color: AppTheme.textDarkPrimary, fontSize: 18, fontWeight: FontWeight.w900,
                      )),
                      const Text('kcal left', style: TextStyle(
                        color: AppTheme.luxeGold, fontSize: 9, fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Calories', style: TextStyle(
                  color: AppTheme.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 10),
                _calStat('Target', '$target kcal', AppTheme.textDarkPrimary),
                const SizedBox(height: 6),
                _calStat('Consumed', '$consumed kcal', AppTheme.luxeGold),
                const SizedBox(height: 6),
                _calStat('Burned', '+$burned kcal', const Color(0xFF4ADE80)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calStat(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrackMealButton() {
    return TouchBounce(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => MealLogView(vitals: widget.vitals, date: _selectedDate),
        ));
        widget.onRefresh();
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.luxeGoldDark, AppTheme.luxeGold]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text('Track Meal', style: TextStyle(
              color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(DailyLog log) {
    final p = log.totalProtein.toInt();
    final c = log.totalCarbs.toInt();
    final f = log.totalFat.toInt();
    return Row(
      children: [
        _macroChip('Protein', '${p}g', '130g', p / 130, const Color(0xFF818CF8)),
        const SizedBox(width: 8),
        _macroChip('Carbs', '${c}g', '240g', c / 240, const Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        _macroChip('Fat', '${f}g', '65g', f / 65, const Color(0xFFF87171)),
      ],
    );
  }

  Widget _macroChip(String label, String consumed, String target, double progress, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(consumed, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('of $target', style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 9)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0), minHeight: 3,
                backgroundColor: AppTheme.borderDark,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTrackers(DailyLog log) {
    final waterPct = log.waterMl / widget.vitals.waterTargetMl;
    final sleepHrs = log.sleepMinutes / 60.0;
    final stepsPct = log.steps / widget.vitals.stepsTarget;

    return Row(
      children: [
        _miniTrackerCard(
          icon: Icons.water_drop, title: 'Water',
          value: '${(log.waterMl / 1000).toStringAsFixed(1)} L',
          sub: '+250ml tap', progress: waterPct, color: const Color(0xFF38BDF8),
          onTap: () {
            final newWater = log.waterMl + 250;
            setState(() => log.waterMl = newWater);
            FirestoreService().saveDailyMetrics(date: _selectedDate, waterMl: newWater);
          },
        ),
        const SizedBox(width: 8),
        _miniTrackerCard(
          icon: Icons.bedtime, title: 'Sleep',
          value: '${sleepHrs.toStringAsFixed(1)} h',
          sub: 'Goal 8.0 h', progress: sleepHrs / 8.0, color: const Color(0xFFA78BFA),
        ),
        const SizedBox(width: 8),
        _miniTrackerCard(
          icon: Icons.directions_walk, title: 'Steps',
          value: '${log.steps}',
          sub: 'Goal 10k', progress: stepsPct, color: const Color(0xFF34D399),
        ),
      ],
    );
  }

  Widget _miniTrackerCard({
    required IconData icon, required String title, required String value,
    required String sub, required double progress, required Color color,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 9)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0), minHeight: 3,
              backgroundColor: AppTheme.borderDark,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Expanded(child: card);
    }

    return Expanded(
      child: TouchBounce(
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildMealsSummary(DailyLog log) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logged Meals Today', style: TextStyle(
                color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.bold,
              )),
              Text('${log.meals.length} items', style: const TextStyle(color: AppTheme.luxeGold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ...log.meals.take(4).map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.luxeGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(m.mealType, style: const TextStyle(color: AppTheme.luxeGold, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(m.food.name, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 12))),
                Text('${m.calories} kcal', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAIAssistant(DailyLog log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.luxeGold.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.luxeGold, size: 20),
              SizedBox(width: 8),
              Text('HealthX AI Assistant', style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Ask anything about your health, nutrition, or workouts.', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          // Fake Input Field
          TouchBounce(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AIAssistantView(
                vitals: widget.vitals,
                log: log,
              )));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Ask me anything...', style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 13))),
                  Icon(Icons.send, color: AppTheme.luxeGold, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Suggested Questions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                _buildAIPromptChip('Analyze my macros today', log),
                const SizedBox(width: 8),
                _buildAIPromptChip('Suggest a high-protein dinner', log),
                const SizedBox(width: 8),
                _buildAIPromptChip('Build a custom rehab & workout plan', log),
                const SizedBox(width: 8),
                _buildAIPromptChip('Why am I feeling tired?', log),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPromptChip(String text, DailyLog log) {
    return TouchBounce(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AIAssistantView(
          vitals: widget.vitals,
          log: log,
          initialQuery: text,
        )));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.luxeGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.luxeGold.withOpacity(0.3)),
        ),
        child: Text(text, style: const TextStyle(color: AppTheme.luxeGold, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIET PLANS SECTION
  // ──────────────────────────────────────────────────────────────────────────

  String _selectedDietCategory = 'Paralysis';
  final List<String> _dietCategories = ['Paralysis', 'Health Issues', 'General'];

  static const Map<String, IconData> _dietCategoryIcons = {
    'Paralysis': Icons.accessibility_new,
    'Health Issues': Icons.monitor_heart,
    'General': Icons.fitness_center,
  };

  static const Map<String, Color> _dietCategoryColors = {
    'Paralysis': Color(0xFF2DD4BF),
    'Health Issues': Color(0xFFF43F5E),
    'General': Color(0xFFD97706),
  };

  Widget _buildDietPlansSection() {
    final filtered = HealthData.dietPlans
        .where((p) => p.category == _selectedDietCategory)
        .toList();
    final catColor = _dietCategoryColors[_selectedDietCategory] ?? AppTheme.luxeGold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.restaurant, color: catColor, size: 16),
                ),
                const SizedBox(width: 9),
                const Text('Curated Diet Plans', style: TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 15,
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
            Text('${filtered.length} plans', style: TextStyle(
              color: catColor, fontSize: 11, fontWeight: FontWeight.bold,
            )),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Curated to your body weight using simple, everyday household foods',
          style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),

        // ── Category Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: _dietCategories.map((cat) {
              final selected = cat == _selectedDietCategory;
              final color = _dietCategoryColors[cat] ?? AppTheme.luxeGold;
              final icon = _dietCategoryIcons[cat] ?? Icons.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDietCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? color : color.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: selected ? Colors.black : color),
                        const SizedBox(width: 6),
                        Text(cat, style: TextStyle(
                          color: selected ? Colors.black : color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // ── Horizontal Cards
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => RepaintBoundary(
              child: _buildDietPlanCard(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDietPlanCard(DietPlan plan) {
    final gradient = plan.gradientColors.length >= 2
        ? LinearGradient(colors: plan.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight)
        : LinearGradient(colors: [plan.accentColor.withOpacity(0.25), plan.accentColor.withOpacity(0.08)]);

    return TouchBounce(
      onTap: () => _promptWeightAndOpenDiet(context, plan),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: plan.accentColor.withOpacity(0.35), width: 1.2),
          boxShadow: [BoxShadow(color: plan.accentColor.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: plan.accentColor.withOpacity(0.4)),
                  ),
                  child: Text(plan.conditionTag ?? plan.category,
                    style: TextStyle(color: plan.accentColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                ),
                const Spacer(),
                Icon(Icons.restaurant_menu, color: plan.accentColor, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.name, style: const TextStyle(
              color: AppTheme.textDarkPrimary, fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.3,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(plan.goal, style: TextStyle(color: plan.accentColor, fontSize: 10, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                _dietMacroChip('P', '${plan.targetProtein.toInt()}g', plan.accentColor),
                const SizedBox(width: 5),
                _dietMacroChip('C', '${plan.targetCarbs.toInt()}g', plan.accentColor),
                const SizedBox(width: 5),
                _dietMacroChip('F', '${plan.targetFat.toInt()}g', plan.accentColor),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.scale_rounded, color: plan.accentColor, size: 12),
                    const SizedBox(width: 4),
                    Text('${plan.dailyCaloriesTarget} kcal',
                      style: TextStyle(color: plan.accentColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: plan.accentColor, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 10, color: Colors.black),
                      SizedBox(width: 3),
                      Text('Curate Plan', style: TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _promptWeightAndOpenDiet(BuildContext context, DietPlan plan) {
    double tempWeight = _log.weightKg.clamp(40.0, 160.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final scale = tempWeight / 70.0;
          final cals = (plan.dailyCaloriesTarget * scale).round();
          final p = (plan.targetProtein * scale).round();
          final c = (plan.targetCarbs * scale).round();
          final f = (plan.targetFat * scale).round();

          return Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: plan.accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: plan.accentColor.withOpacity(0.35)),
                        ),
                        child: Icon(Icons.monitor_weight_rounded, color: plan.accentColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: plan.accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (plan.conditionTag ?? plan.category).toUpperCase(),
                                style: TextStyle(
                                  color: plan.accentColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'First, Input Your Body Weight',
                              style: TextStyle(
                                color: AppTheme.textDarkPrimary,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: AppTheme.textDarkSecondary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'To curate "${plan.name}" with exact daily calories and easy household meal portions, select your current body weight:',
                    style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  // Weight Stepper Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: plan.accentColor.withOpacity(0.35), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TouchBounce(
                          onTap: () {
                            if (tempWeight > 40.0) {
                              setModalState(() => tempWeight = (tempWeight - 0.5).clamp(40.0, 160.0));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: const Icon(Icons.remove, color: AppTheme.textDarkPrimary, size: 20),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${tempWeight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: plan.accentColor,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '≈ ${(tempWeight * 2.20462).toStringAsFixed(1)} lbs  •  $cals kcal / day',
                              style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        TouchBounce(
                          onTap: () {
                            if (tempWeight < 160.0) {
                              setModalState(() => tempWeight = (tempWeight + 0.5).clamp(40.0, 160.0));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: const Icon(Icons.add, color: AppTheme.textDarkPrimary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: plan.accentColor,
                      inactiveTrackColor: AppTheme.borderDark,
                      thumbColor: plan.accentColor,
                      overlayColor: plan.accentColor.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: tempWeight.clamp(40.0, 140.0),
                      min: 40.0,
                      max: 140.0,
                      divisions: 200,
                      onChanged: (val) {
                        setModalState(() => tempWeight = (val * 2).round() / 2);
                      },
                    ),
                  ),

                  // Quick Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [50.0, 60.0, 70.0, 80.0, 90.0, 100.0].map((w) {
                      final isSel = (tempWeight - w).abs() < 0.3;
                      return TouchBounce(
                        onTap: () => setModalState(() => tempWeight = w),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? plan.accentColor : AppTheme.bgDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSel ? plan.accentColor : AppTheme.borderDark),
                          ),
                          child: Text(
                            '${w.toInt()} kg',
                            style: TextStyle(
                              color: isSel ? Colors.black : AppTheme.textDarkPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Live Calibrated Breakdown Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: plan.accentColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Calibrated Targets for ${tempWeight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: AppTheme.textDarkPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _macroPill('Calories', '$cals', 'kcal', plan.accentColor),
                            _macroPill('Protein', '$p', 'g', const Color(0xFF60A5FA)),
                            _macroPill('Carbs', '$c', 'g', const Color(0xFFFBBF24)),
                            _macroPill('Fat', '$f', 'g', const Color(0xFFF87171)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Simple Everyday Foods Assurance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Uses simple, recognizable everyday foods: eggs, milk, curd, yellow dal, chicken, paneer, chapatis, rice, seasonal fruits & vegetables.',
                            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 10.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Continue Button
                  TouchBounce(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DietWeekView(
                            plan: plan,
                            initialWeightKg: tempWeight,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [plan.accentColor, plan.accentColor.withOpacity(0.85)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: plan.accentColor.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Design 7-Day Plan for ${tempWeight.toStringAsFixed(1)} kg →',
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _macroPill(String title, String val, String unit, Color col) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 9.5)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: val,
            style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: ' $unit', style: TextStyle(color: col.withOpacity(0.7), fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dietMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
          Text(value, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PremiumLockOverlay extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final VoidCallback onUnlockTap;

  const _PremiumLockOverlay({required this.child, required this.isLocked, required this.onUnlockTap});

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    return Stack(
      children: [
        IgnorePointer(child: child),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: TouchBounce(
              onTap: onUnlockTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.luxeGold.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.black, size: 16),
                    SizedBox(width: 6),
                    Text('Unlock with Pro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

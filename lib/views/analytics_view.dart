import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../widgets/healthx_logo.dart';
import '../widgets/touch_bounce.dart';
import '../services/firestore_service.dart';

class AnalyticsView extends StatefulWidget {
  final UserVitals vitals;
  final bool isDarkMode;

  const AnalyticsView({Key? key, required this.vitals, required this.isDarkMode}) : super(key: key);

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  bool _isEditing = false;
  bool _isSaving = false;

  late double _weight;
  late double _startingWeight;
  late double _targetWeight;
  late double _height;
  late int _age;
  late String _gender;
  late String _activityLevel;
  late String _goal;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  @override
  void didUpdateWidget(covariant AnalyticsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _loadValues();
    }
  }

  void _loadValues() {
    _weight = widget.vitals.currentWeightKg;
    _startingWeight = widget.vitals.startingWeightKg;
    _targetWeight = widget.vitals.targetWeightKg;
    _height = widget.vitals.heightCm;
    _age = widget.vitals.age;
    _gender = widget.vitals.gender;
    _activityLevel = widget.vitals.activityLevel;
    _goal = widget.vitals.goal;
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      setState(() {
        widget.vitals.currentWeightKg = _weight;
        widget.vitals.startingWeightKg = _startingWeight;
        widget.vitals.targetWeightKg = _targetWeight;
        widget.vitals.heightCm = _height;
        widget.vitals.age = _age;
        widget.vitals.gender = _gender;
        widget.vitals.activityLevel = _activityLevel;
        widget.vitals.goal = _goal;

        // Recalculate target calories based on BMR & TDEE
        widget.vitals.targetCalories = widget.vitals.calculatedRecommendedCalories;
        widget.vitals.todayLog.weightKg = _weight;
        _isEditing = false;
        _isSaving = false;
      });

      // Persist to Cloud Firestore and local storage cache
      await FirestoreService().saveUserProfile(widget.vitals);
      await FirestoreService().saveDailyMetrics(
        date: DateTime.now(),
        weightKg: _weight,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.black, size: 18),
              SizedBox(width: 8),
              Text('Body metrics & transformation synced successfully!',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.luxeGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to sync metrics: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically use live values during edit mode for real-time preview
    final currentStartW = _isEditing ? _startingWeight : widget.vitals.startingWeightKg;
    final currentWeightW = _isEditing ? _weight : widget.vitals.currentWeightKg;
    final currentTargetW = _isEditing ? _targetWeight : widget.vitals.targetWeightKg;
    final currentHeight = _isEditing ? _height : widget.vitals.heightCm;
    final currentAge = _isEditing ? _age : widget.vitals.age;
    final currentGender = _isEditing ? _gender : widget.vitals.gender;
    final currentActivity = _isEditing ? _activityLevel : widget.vitals.activityLevel;
    final currentGoal = _isEditing ? _goal : widget.vitals.goal;

    // Live BMI calculation
    final hM = currentHeight / 100.0;
    final bmi = hM > 0 ? (currentWeightW / (hM * hM)) : 22.0;

    Color bmiColor;
    String bmiStatus;
    if (bmi < 18.5) {
      bmiColor = const Color(0xFF38BDF8);
      bmiStatus = 'Underweight';
    } else if (bmi < 25.0) {
      bmiColor = const Color(0xFF34D399);
      bmiStatus = 'Healthy Weight';
    } else if (bmi < 30.0) {
      bmiColor = const Color(0xFFFBBF24);
      bmiStatus = 'Overweight';
    } else {
      bmiColor = const Color(0xFFF87171);
      bmiStatus = 'Obese';
    }

    // Live BMR & TDEE calculation
    final bmr = currentGender == 'Female'
        ? (10 * currentWeightW + 6.25 * currentHeight - 5 * currentAge - 161)
        : (10 * currentWeightW + 6.25 * currentHeight - 5 * currentAge + 5);

    double mult;
    switch (currentActivity) {
      case 'Sedentary': mult = 1.2; break;
      case 'Lightly Active': mult = 1.375; break;
      case 'Moderately Active': mult = 1.55; break;
      case 'Very Active': mult = 1.725; break;
      case 'Extra Active': mult = 1.9; break;
      default: mult = 1.55;
    }
    final tdee = bmr * mult;

    int recCal;
    if (currentGoal == 'Weight Loss') {
      recCal = (tdee - 500).round();
    } else if (currentGoal == 'Muscle Gain') {
      recCal = (tdee + 350).round();
    } else {
      recCal = tdee.round();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HealthXLogo(size: 32, fontSize: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_isEditing) {
                          _loadValues(); // Reset on cancel
                        }
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit_note, color: Colors.black, size: 16),
                    label: Text(_isEditing ? 'Cancel' : 'Edit Metrics',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.luxeGold,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Body Analytics & Metrics',
                  style: TextStyle(
                    color: AppTheme.textDarkPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  )),
              Text(
                _isEditing
                    ? 'Adjust values below to preview your transformation journey and metabolic changes live.'
                    : 'Tap any card or "Edit Metrics" to adjust starting weight, target goal, BMR and calories.',
                style: const TextStyle(color: AppTheme.luxeGold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Interactive Edit Panel if enabled
              if (_isEditing) ...[
                _buildEditMetricsForm(),
                const SizedBox(height: 16),
              ],

              // Weight Transformation Journey Panel (Primary Focus)
              _buildTransformationJourneyCard(
                startW: currentStartW,
                currW: currentWeightW,
                targetW: currentTargetW,
                goal: currentGoal,
              ),
              const SizedBox(height: 14),

              // BMI Card
              _section(
                title: 'Body Mass Index (BMI)',
                action: Text(bmiCategoryText(bmiStatus),
                    style: TextStyle(color: bmiColor, fontSize: 11, fontWeight: FontWeight.bold)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bmi.toStringAsFixed(1),
                                style: TextStyle(
                                  color: bmiColor,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bmiColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(bmiStatus,
                                  style: TextStyle(color: bmiColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _bmiScale(bmi),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calorie Recommendations
              _section(
                title: 'Daily Energy Goal',
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.luxeGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.luxeGold.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: AppTheme.luxeGold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Recommended Intake for Goal',
                                    style: TextStyle(color: AppTheme.luxeGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('Based on $currentGoal and $currentActivity activity level',
                                    style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text('$recCal kcal',
                              style: const TextStyle(color: AppTheme.luxeGold, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Metabolic Details Grid (BMR, TDEE, Safe Rate)
              Row(
                children: [
                  Expanded(
                    child: _metaCard(
                      'Basal Metabolic Rate',
                      '${bmr.round()} kcal',
                      'Resting energy needed for vital organs',
                      const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metaCard(
                      'Total Daily Burn',
                      '${tdee.round()} kcal',
                      'Total expenditure with $currentActivity',
                      AppTheme.luxeGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WEIGHT TRANSFORMATION JOURNEY PANEL ─────────────────────────────────────

  Widget _buildTransformationJourneyCard({
    required double startW,
    required double currW,
    required double targetW,
    required String goal,
  }) {
    // 1. Determine Journey Direction:
    final bool isGain = targetW > startW;
    final bool isMaintenance = (targetW - startW).abs() < 0.2;
    final bool isLoss = !isGain && !isMaintenance;

    final double totalDelta = (targetW - startW).abs();

    double progressAchieved;
    double remainingToGoal;
    double progressFraction;
    String statusLabel;
    String badgeText;
    Color badgeColor;
    String deltaText;

    if (isMaintenance) {
      final variance = (currW - targetW).abs();
      progressAchieved = variance;
      remainingToGoal = 0.0;
      if (variance <= 1.0) {
        progressFraction = 1.0;
        statusLabel = 'Optimal Stability';
        deltaText = '±${variance.toStringAsFixed(1)} kg variance';
      } else {
        progressFraction = (1.0 - ((variance - 1.0) / 4.0)).clamp(0.1, 0.95);
        statusLabel = 'Fluctuating';
        deltaText = '${currW > targetW ? '+' : '-'}${variance.toStringAsFixed(1)} kg';
      }
      badgeText = '⚖️ MAINTENANCE';
      badgeColor = const Color(0xFF818CF8);
    } else if (isGain) {
      // Muscle / Weight Gain Goal
      progressAchieved = currW - startW;
      remainingToGoal = targetW - currW;
      if (remainingToGoal <= 0) {
        remainingToGoal = 0.0;
        progressFraction = 1.0;
        statusLabel = 'Goal Met! 🎉';
      } else {
        progressFraction = totalDelta > 0 ? (progressAchieved / totalDelta).clamp(0.0, 1.0) : 0.0;
        statusLabel = '${(progressFraction * 100).round()}% Completed';
      }
      badgeText = '💪 MUSCLE GAIN';
      badgeColor = const Color(0xFF38BDF8);
      deltaText = progressAchieved >= 0
          ? '+${progressAchieved.toStringAsFixed(1)} kg gained'
          : '${progressAchieved.toStringAsFixed(1)} kg lost';
    } else {
      // Weight Loss Goal
      progressAchieved = startW - currW;
      remainingToGoal = currW - targetW;
      if (remainingToGoal <= 0) {
        remainingToGoal = 0.0;
        progressFraction = 1.0;
        statusLabel = 'Goal Met! 🎉';
      } else {
        progressFraction = totalDelta > 0 ? (progressAchieved / totalDelta).clamp(0.0, 1.0) : 0.0;
        statusLabel = '${(progressFraction * 100).round()}% Completed';
      }
      badgeText = '📉 WEIGHT LOSS';
      badgeColor = const Color(0xFF34D399);
      deltaText = progressAchieved >= 0
          ? '-${progressAchieved.toStringAsFixed(1)} kg lost'
          : '+${(-progressAchieved).toStringAsFixed(1)} kg gained';
    }

    final bool isDone = progressFraction >= 1.0;

    return TouchBounce(
      onTap: () {
        if (!_isEditing) setState(() => _isEditing = true);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isEditing ? AppTheme.luxeGold.withOpacity(0.45) : AppTheme.borderDark,
            width: _isEditing ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isEditing)
              BoxShadow(color: AppTheme.luxeGold.withOpacity(0.08), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.luxeGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: AppTheme.luxeGold, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weight Transformation Journey',
                          style: TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(
                        _isEditing ? '⚡ Live Tuning Preview' : 'Interactive Milestones & Progress',
                        style: TextStyle(
                          color: _isEditing ? AppTheme.luxeGold : AppTheme.textDarkMuted,
                          fontSize: 10,
                          fontWeight: _isEditing ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Goal Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Milestone Route Nodes: Start -> Current -> Target
            Row(
              children: [
                _milestoneNode(
                  label: 'START',
                  value: '${startW.toStringAsFixed(1)} kg',
                  subtitle: 'Baseline',
                  icon: Icons.flag_outlined,
                  color: AppTheme.textDarkSecondary,
                  borderColor: AppTheme.borderDark,
                ),
                _connectorArrow(),
                _milestoneNode(
                  label: 'CURRENT',
                  value: '${currW.toStringAsFixed(1)} kg',
                  subtitle: deltaText,
                  icon: Icons.monitor_weight_outlined,
                  color: AppTheme.luxeGold,
                  borderColor: AppTheme.luxeGold,
                  isHighlighted: true,
                ),
                _connectorArrow(),
                _milestoneNode(
                  label: 'TARGET',
                  value: '${targetW.toStringAsFixed(1)} kg',
                  subtitle: isLoss ? 'Goal Target' : (isGain ? 'Target Bulk' : 'Maintain'),
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFF34D399),
                  borderColor: const Color(0xFF34D399).withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visual Progress Track (Multi-stop Gradient Bar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Overall Progress',
                            style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        if (_isEditing) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.luxeGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LIVE',
                                style: TextStyle(color: AppTheme.luxeGold, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDone ? const Color(0xFF34D399) : AppTheme.luxeGold).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: (isDone ? const Color(0xFF34D399) : AppTheme.luxeGold).withOpacity(0.4)),
                      ),
                      child: Text(
                        isDone ? '🎉 GOAL ACHIEVED' : statusLabel.toUpperCase(),
                        style: TextStyle(
                          color: isDone ? const Color(0xFF34D399) : AppTheme.luxeGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final fillWidth = (barWidth * progressFraction).clamp(0.0, barWidth);
                  return Stack(
                    children: [
                      Container(
                        height: 10,
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDarkElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderDark, width: 0.8),
                        ),
                      ),
                      Container(
                        height: 10,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: isGain
                                ? [AppTheme.luxeGold, const Color(0xFF38BDF8)]
                                : [const Color(0xFF10B981), AppTheme.luxeGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isGain ? const Color(0xFF38BDF8) : AppTheme.luxeGold).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),

            // 3 Stat Micro Cards
            Row(
              children: [
                _statPill(
                  title: 'TOTAL GOAL',
                  value: '${totalDelta.toStringAsFixed(1)} kg',
                  sub: isLoss ? 'To shed' : (isGain ? 'To build' : 'Target'),
                  color: AppTheme.textDarkPrimary,
                ),
                const SizedBox(width: 8),
                _statPill(
                  title: isLoss ? 'LOST SO FAR' : (isGain ? 'GAINED SO FAR' : 'VARIANCE'),
                  value: '${progressAchieved >= 0 ? (isLoss ? '-' : '+') : ''}${progressAchieved.abs().toStringAsFixed(1)} kg',
                  sub: isDone ? 'Target met' : 'Achieved',
                  color: progressAchieved >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                ),
                const SizedBox(width: 8),
                _statPill(
                  title: 'REMAINING',
                  value: remainingToGoal <= 0 ? '0.0 kg' : '${remainingToGoal.toStringAsFixed(1)} kg',
                  sub: remainingToGoal <= 0 ? 'Goal met 🎉' : (isLoss ? 'To target' : 'To gain'),
                  color: remainingToGoal <= 0 ? const Color(0xFF34D399) : AppTheme.luxeGold,
                ),
              ],
            ),

            // Celebratory Note if Done
            if (isDone) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFF34D399), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Outstanding milestone! You have reached your target weight. Consider adjusting your goal or switching to Maintenance mode.',
                        style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _milestoneNode({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color borderColor,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppTheme.luxeGold.withOpacity(0.09) : AppTheme.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1),
          boxShadow: isHighlighted
              ? [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.12), blurRadius: 10)]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 11),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  color: isHighlighted ? AppTheme.luxeGold : AppTheme.textDarkMuted,
                  fontSize: 8.5,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectorArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.borderDark, size: 10),
    );
  }

  Widget _statPill({required String title, required String value, required String sub, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  color: AppTheme.textDarkMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── EDIT METRICS FORM ───────────────────────────────────────────────────────

  Widget _buildEditMetricsForm() {
    final activityOptions = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'];
    final goalOptions = ['Weight Loss', 'Muscle Gain', 'Maintenance'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.luxeGold, width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.12), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppTheme.luxeGold, size: 16),
                  SizedBox(width: 8),
                  Text('Update Body Composition',
                      style: TextStyle(
                        color: AppTheme.luxeGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: AppTheme.luxeGold.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('MANUAL TUNING',
                    style: TextStyle(color: AppTheme.luxeGold, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gender & Age Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _genderChip('Male'),
                        const SizedBox(width: 6),
                        _genderChip('Female'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Age: $_age yrs', style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11)),
                    Slider(
                      value: _age.toDouble().clamp(15, 80),
                      min: 15,
                      max: 80,
                      divisions: 65,
                      activeColor: AppTheme.luxeGold,
                      inactiveColor: AppTheme.borderDark,
                      onChanged: (v) => setState(() => _age = v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.borderDark, height: 20),

          // Starting Weight Slider with Steppers
          _sliderRow(
            'Starting Weight (Baseline)',
            '${_startingWeight.toStringAsFixed(1)} kg',
            _startingWeight.clamp(40, 160),
            40,
            160,
            240,
            (v) => setState(() => _startingWeight = double.parse(v.toStringAsFixed(1))),
            onDec: () => setState(() => _startingWeight = (_startingWeight - 0.5).clamp(40, 160)),
            onInc: () => setState(() => _startingWeight = (_startingWeight + 0.5).clamp(40, 160)),
          ),
          const SizedBox(height: 8),

          // Current Weight Slider with Steppers
          _sliderRow(
            'Current Weight (Today)',
            '${_weight.toStringAsFixed(1)} kg',
            _weight.clamp(40, 160),
            40,
            160,
            240,
            (v) => setState(() => _weight = double.parse(v.toStringAsFixed(1))),
            onDec: () => setState(() => _weight = (_weight - 0.5).clamp(40, 160)),
            onInc: () => setState(() => _weight = (_weight + 0.5).clamp(40, 160)),
          ),
          const SizedBox(height: 8),

          // Target Weight Slider with Steppers
          _sliderRow(
            'Target Weight (Goal)',
            '${_targetWeight.toStringAsFixed(1)} kg',
            _targetWeight.clamp(40, 160),
            40,
            160,
            240,
            (v) => setState(() => _targetWeight = double.parse(v.toStringAsFixed(1))),
            onDec: () => setState(() => _targetWeight = (_targetWeight - 0.5).clamp(40, 160)),
            onInc: () => setState(() => _targetWeight = (_targetWeight + 0.5).clamp(40, 160)),
          ),
          const SizedBox(height: 8),

          // Height Slider
          _sliderRow(
            'Height',
            '${_height.toInt()} cm',
            _height.clamp(130, 220),
            130,
            220,
            90,
            (v) => setState(() => _height = v.roundToDouble()),
            onDec: () => setState(() => _height = (_height - 1.0).clamp(130, 220)),
            onInc: () => setState(() => _height = (_height + 1.0).clamp(130, 220)),
          ),
          const Divider(color: AppTheme.borderDark, height: 20),

          // Activity Level selector
          const Text('Activity Level',
              style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: activityOptions.map((opt) {
              final sel = _activityLevel == opt;
              return ChoiceChip(
                label: Text(opt,
                    style: TextStyle(
                      color: sel ? Colors.black : AppTheme.textDarkSecondary,
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    )),
                selected: sel,
                selectedColor: AppTheme.luxeGold,
                backgroundColor: AppTheme.surfaceDarkElevated,
                onSelected: (b) => setState(() => _activityLevel = opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Goal selector
          const Text('Primary Fitness Goal',
              style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: goalOptions.map((g) {
              final sel = _goal == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Center(
                        child: Text(g,
                            style: TextStyle(
                              color: sel ? Colors.black : AppTheme.textDarkSecondary,
                              fontSize: 10,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            ))),
                    selected: sel,
                    selectedColor: AppTheme.luxeGold,
                    backgroundColor: AppTheme.surfaceDarkElevated,
                    onSelected: (b) => setState(() => _goal = g),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.check, color: Colors.black, size: 18),
              label: Text(
                _isSaving ? 'Saving & Syncing...' : 'Save & Recalculate Metrics',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.luxeGold,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label) {
    final sel = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppTheme.luxeGold : AppTheme.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? AppTheme.luxeGold : AppTheme.borderDark),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: sel ? Colors.black : AppTheme.textDarkSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    String valueStr,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged, {
    VoidCallback? onDec,
    VoidCallback? onInc,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            Row(
              children: [
                if (onDec != null)
                  InkWell(
                    onTap: onDec,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Icon(Icons.remove, color: AppTheme.luxeGold, size: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(valueStr,
                      style: const TextStyle(color: AppTheme.luxeGold, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                if (onInc != null)
                  InkWell(
                    onTap: onInc,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Icon(Icons.add, color: AppTheme.luxeGold, size: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.luxeGold,
          inactiveColor: AppTheme.borderDark,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _section({required String title, Widget? action, required Widget child}) {
    return TouchBounce(
      onTap: () {
        if (!_isEditing) {
          setState(() => _isEditing = true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppTheme.textDarkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    )),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String bmiCategoryText(String cat) {
    switch (cat) {
      case 'Underweight': return 'Below recommended range';
      case 'Healthy Weight': return 'Optimal health range';
      case 'Overweight': return 'Slightly above range';
      default: return 'Above recommended range';
    }
  }

  Widget _bmiScale(double bmi) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scaleRow('< 18.5', 'Underweight', const Color(0xFF38BDF8), bmi < 18.5),
          _scaleRow('18.5–24.9', 'Healthy', const Color(0xFF34D399), bmi >= 18.5 && bmi < 25),
          _scaleRow('25–29.9', 'Overweight', const Color(0xFFFBBF24), bmi >= 25 && bmi < 30),
          _scaleRow('≥ 30', 'Obese', const Color(0xFFF87171), bmi >= 30),
        ],
      ),
    );
  }

  Widget _scaleRow(String range, String label, Color color, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: active ? color : AppTheme.borderDark, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$range $label',
              style: TextStyle(
                color: active ? color : AppTheme.textDarkMuted,
                fontSize: 9,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _metaCard(String title, String val, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(desc, style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 9, height: 1.3)),
        ],
      ),
    );
  }
}

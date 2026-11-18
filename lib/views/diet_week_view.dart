import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../models/diet_week_models.dart';
import '../data/diet_week_data.dart';
import '../theme/app_theme.dart';
import '../widgets/touch_bounce.dart';

class DietWeekView extends StatefulWidget {
  final DietPlan plan;
  final double initialWeightKg;

  const DietWeekView({
    Key? key,
    required this.plan,
    this.initialWeightKg = 70.0,
  }) : super(key: key);

  @override
  State<DietWeekView> createState() => _DietWeekViewState();
}

class _DietWeekViewState extends State<DietWeekView> {
  late double _currentWeight;
  late List<DietWeekOption> _options;
  int _selectedOptionIndex = 0;
  int _selectedDayIndex = 0;
  bool _showAllDays = false;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeightKg.clamp(40.0, 160.0);
    _options = DietWeekData.getWeeklyOptions(widget.plan, weightKg: _currentWeight);
  }

  void _updateWeight(double newWeight) {
    setState(() {
      _currentWeight = newWeight.clamp(40.0, 160.0);
      _options = DietWeekData.getWeeklyOptions(widget.plan, weightKg: _currentWeight);
    });
  }

  DietWeekOption get _currentOption {
    if (_options.isEmpty) {
      return DietWeekOption(
        id: 'default',
        title: 'Option 1: Balanced Plan',
        tag: 'Standard',
        description: 'Comprehensive weekly nutrition plan.',
        accentColor: widget.plan.accentColor,
        days: const [],
      );
    }
    return _options[_selectedOptionIndex.clamp(0, _options.length - 1)];
  }

  DietDayPlan? get _currentDay {
    final days = _currentOption.days;
    if (days.isEmpty) return null;
    return days[_selectedDayIndex.clamp(0, days.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final option = _currentOption;
    final currentDay = _currentDay;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ──────────────────────────────────────────
            _buildAppBar(context, plan),

            // ── Main Content ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight Calibration Bar
                    _buildWeightBar(plan),
                    const SizedBox(height: 14),

                    // Plan Overview Hero Banner
                    _buildPlanHeroCard(plan),
                    const SizedBox(height: 20),

                    // 4 Options Selector Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choose Weekly Option',
                          style: TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: plan.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: plan.accentColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_options.length} Variations',
                            style: TextStyle(
                              color: plan.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select the weekly structure that fits your daily routine & recovery stage:',
                      style: TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4 Options Horizontal / Grid Selector
                    _buildOptionsSelector(plan),
                    const SizedBox(height: 20),

                    // Active Option Description Banner
                    _buildActiveOptionBanner(option),
                    const SizedBox(height: 20),

                    // Day View Mode Toggle & Day Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: option.accentColor),
                            const SizedBox(width: 8),
                            const Text(
                              '7-Day Meal Schedule',
                              style: TextStyle(
                                color: AppTheme.textDarkPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TouchBounce(
                          onTap: () => setState(() => _showAllDays = !_showAllDays),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _showAllDays ? option.accentColor.withOpacity(0.2) : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showAllDays ? option.accentColor : AppTheme.borderDark,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showAllDays ? Icons.view_day_rounded : Icons.view_week_rounded,
                                  size: 13,
                                  color: _showAllDays ? option.accentColor : AppTheme.textDarkSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _showAllDays ? 'Day View' : 'All 7 Days',
                                  style: TextStyle(
                                    color: _showAllDays ? option.accentColor : AppTheme.textDarkSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 7 Days Pill Selector (shown if not expanded to all days)
                    if (!_showAllDays && option.days.isNotEmpty) ...[
                      _buildDaysTabBar(option),
                      const SizedBox(height: 16),
                    ],

                    // Meals Content: Single Day or All 7 Days
                    if (_showAllDays)
                      ...option.days.map((day) => _buildDaySection(day, option.accentColor))
                    else if (currentDay != null)
                      _buildSingleDayView(currentDay, option.accentColor),

                    const SizedBox(height: 24),

                    // Power Foods & Plan Principles
                    _buildKeyFoodsSection(plan),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DietPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 0.5)),
      ),
      child: Row(
        children: [
          TouchBounce(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: plan.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plan.conditionTag ?? plan.category,
                        style: TextStyle(
                          color: plan.accentColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: AppTheme.textDarkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanHeroCard(DietPlan plan) {
    final scale = _currentWeight / 70.0;
    final scaledCalories = (plan.dailyCaloriesTarget * scale).round();
    final scaledProtein = (plan.targetProtein * scale).round();
    final scaledCarbs = (plan.targetCarbs * scale).round();
    final scaledFat = (plan.targetFat * scale).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plan.gradientColors.length >= 2
              ? [plan.gradientColors[0], plan.gradientColors[1]]
              : [plan.accentColor.withOpacity(0.2), AppTheme.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: plan.accentColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: plan.accentColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: plan.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant_menu_rounded, color: plan.accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.goal,
                      style: TextStyle(
                        color: plan.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.description,
            style: const TextStyle(
              color: AppTheme.textDarkSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          // Daily Macro Targets Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: plan.accentColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroMacroTile('Calories', '$scaledCalories', 'kcal', plan.accentColor),
                _heroDivider(),
                _heroMacroTile('Protein', '$scaledProtein', 'g', const Color(0xFF818CF8)),
                _heroDivider(),
                _heroMacroTile('Carbs', '$scaledCarbs', 'g', const Color(0xFFFBBF24)),
                _heroDivider(),
                _heroMacroTile('Fat', '$scaledFat', 'g', const Color(0xFFF87171)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightBar(DietPlan plan) {
    final scale = _currentWeight / 70.0;
    final scaledCals = (plan.dailyCaloriesTarget * scale).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: plan.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.accentColor.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: plan.accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.monitor_weight_rounded, color: plan.accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Curated For: ', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11.5)),
                    Text(
                      '${_currentWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(color: plan.accentColor, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily Target: $scaledCals kcal • Scaled Portions',
                  style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TouchBounce(
            onTap: () => _showWeightDialog(context, plan),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: plan.accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 12, color: Colors.black),
                  SizedBox(width: 4),
                  Text('Change Weight', style: TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, DietPlan plan) {
    double tempWeight = _currentWeight;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final scale = tempWeight / 70.0;
          final cals = (plan.dailyCaloriesTarget * scale).round();
          final p = (plan.targetProtein * scale).round();

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: plan.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.monitor_weight_rounded, color: plan.accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Curate by Body Weight',
                      style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adjust your body weight to instantly calculate your daily calories, protein needs, and meal portions:',
                  style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Weight Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: plan.accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TouchBounce(
                        onTap: () {
                          if (tempWeight > 40) {
                            setModalState(() => tempWeight -= 0.5);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: const Icon(Icons.remove, color: AppTheme.textDarkPrimary, size: 18),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${tempWeight.toStringAsFixed(1)} kg',
                            style: TextStyle(color: plan.accentColor, fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '≈ ${(tempWeight * 2.20462).toStringAsFixed(1)} lbs  •  $cals kcal/day ($p g protein)',
                            style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      TouchBounce(
                        onTap: () {
                          if (tempWeight < 160) {
                            setModalState(() => tempWeight += 0.5);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: const Icon(Icons.add, color: AppTheme.textDarkPrimary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
                // Quick Preset Chips
                Wrap(
                  spacing: 8,
                  children: [50.0, 60.0, 70.0, 80.0, 90.0, 100.0].map((w) {
                    final isSel = (tempWeight - w).abs() < 0.3;
                    return TouchBounce(
                      onTap: () => setModalState(() => tempWeight = w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const SizedBox(height: 24),
                // Apply Button
                TouchBounce(
                  onTap: () {
                    _updateWeight(tempWeight);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: plan.accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: plan.accentColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      'Apply ${tempWeight.toStringAsFixed(1)} kg & Recalculate Plan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 26,
      color: AppTheme.borderDark,
    );
  }

  Widget _heroMacroTile(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSelector(DietPlan plan) {
    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, idx) {
          final opt = _options[idx];
          final selected = idx == _selectedOptionIndex;
          return TouchBounce(
            onTap: () => setState(() => _selectedOptionIndex = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 175,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? opt.accentColor.withOpacity(0.15) : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? opt.accentColor : AppTheme.borderDark,
                  width: selected ? 1.8 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: opt.accentColor.withOpacity(0.2), blurRadius: 10)]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: opt.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          opt.tag,
                          style: TextStyle(
                            color: opt.accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: opt.accentColor, size: 16)
                      else
                        const Icon(Icons.radio_button_unchecked, color: AppTheme.textDarkMuted, size: 15),
                    ],
                  ),
                  Text(
                    opt.title,
                    style: TextStyle(
                      color: selected ? AppTheme.textDarkPrimary : AppTheme.textDarkSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '7 Days • Varied Meals',
                    style: TextStyle(
                      color: selected ? opt.accentColor : AppTheme.textDarkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  Widget _buildActiveOptionBanner(DietWeekOption option) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: option.accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: option.accentColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.stars_rounded, color: option.accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: TextStyle(
                    color: option.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option.description,
                  style: const TextStyle(
                    color: AppTheme.textDarkSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysTabBar(DietWeekOption option) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: option.days.asMap().entries.map((entry) {
          final idx = entry.key;
          final day = entry.value;
          final selected = idx == _selectedDayIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TouchBounce(
              onTap: () => setState(() => _selectedDayIndex = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? option.accentColor : AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? option.accentColor : AppTheme.borderDark,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: option.accentColor.withOpacity(0.3), blurRadius: 8)]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.dayShort,
                      style: TextStyle(
                        color: selected ? Colors.black : AppTheme.textDarkSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Day ${day.dayNumber}',
                      style: TextStyle(
                        color: selected ? Colors.black.withOpacity(0.8) : AppTheme.textDarkMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleDayView(DietDayPlan day, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Focus Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'DAY ${day.dayNumber} • ${day.dayName.toUpperCase()}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${day.totalCalories} kcal',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                day.dayFocus,
                style: const TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (day.dailyTip.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        day.dailyTip,
                        style: const TextStyle(
                          color: AppTheme.textDarkSecondary,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Day Macros Breakdown Bar
              Row(
                children: [
                  _macroPill('Protein', '${day.totalProtein.toInt()}g', const Color(0xFF818CF8)),
                  const SizedBox(width: 6),
                  _macroPill('Carbs', '${day.totalCarbs.toInt()}g', const Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  _macroPill('Fat', '${day.totalFat.toInt()}g', const Color(0xFFF87171)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Meal Cards
        ...day.meals.map((meal) => _buildMealCard(meal, accentColor)),
      ],
    );
  }

  Widget _buildDaySection(DietDayPlan day, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${day.dayNumber} • ${day.dayName}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${day.totalCalories} kcal • P:${day.totalProtein.toInt()}g C:${day.totalCarbs.toInt()}g F:${day.totalFat.toInt()}g',
                style: const TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            day.dayFocus,
            style: const TextStyle(
              color: AppTheme.textDarkPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...day.meals.map((meal) => _buildMealCard(meal, accentColor)),
        ],
      ),
    );
  }

  Widget _buildMealCard(DietMealItem meal, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meal.type.toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          meal.time,
                          style: const TextStyle(
                            color: AppTheme.textDarkMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.name,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    if (meal.portion.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Portion: ${meal.portion}',
                        style: const TextStyle(
                          color: AppTheme.textDarkSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (meal.tip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${meal.tip}',
                style: TextStyle(
                  color: accentColor.withOpacity(0.9),
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _mealMacroChip('${meal.calories} kcal', AppTheme.textDarkPrimary),
              const SizedBox(width: 4),
              _mealMacroChip('P: ${meal.protein.toInt()}g', const Color(0xFF818CF8)),
              const SizedBox(width: 4),
              _mealMacroChip('C: ${meal.carbs.toInt()}g', const Color(0xFFFBBF24)),
              const SizedBox(width: 4),
              _mealMacroChip('F: ${meal.fat.toInt()}g', const Color(0xFFF87171)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _mealMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildKeyFoodsSection(DietPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: plan.accentColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Everyday Power Foods (Simple & Accessible)',
                style: TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Simple, nutritious household ingredients you can easily find at any local grocery store:',
            style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.keyFoods.map((food) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: plan.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: plan.accentColor.withOpacity(0.35)),
                ),
                child: Text(
                  '🌿 $food',
                  style: TextStyle(
                    color: plan.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../data/health_data.dart';
import '../widgets/healthx_logo.dart';

class WorkoutsView extends StatefulWidget {
  final bool isDarkMode;
  final Function(int calories, int mins) onWorkoutCompleted;

  const WorkoutsView({Key? key, required this.isDarkMode, required this.onWorkoutCompleted}) : super(key: key);

  @override
  State<WorkoutsView> createState() => _WorkoutsViewState();
}

class _WorkoutsViewState extends State<WorkoutsView> {
  int _workoutMode = 0; // 0: Curated Multi-Week Plans (27), 1: Single Exercise Modules (30+)
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _planCategories = [
    'All',
    'Paralysis Rehab',
    'Health Issues',
    'Fitness',
  ];

  final List<String> _exerciseCategories = [
    'All',
    'Paralysis Rehab',
    'Health Issues',
    'Strength',
    'Cardio',
    'Fat Loss',
    'Flexibility',
    'Recovery',
  ];

  void _showStartWorkoutModal(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _WorkoutActiveModal(
        exercise: exercise, onComplete: widget.onWorkoutCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _workoutMode == 0 ? _planCategories : _exerciseCategories;

    var filteredExercises = _selectedCategory == 'All'
        ? HealthData.sampleExercises
        : HealthData.sampleExercises.where((ex) => ex.category == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      filteredExercises = filteredExercises.where((ex) =>
          ex.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.targetMuscles.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ex.conditionBadge?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    var filteredPlans = _selectedCategory == 'All'
        ? HealthData.curatedWorkoutPlans
        : HealthData.curatedWorkoutPlans.where((p) => p.category == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      filteredPlans = filteredPlans.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.goal.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.conditionBadge?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
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
              // Top Bar with Logo & Stats
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
                      children: [
                        Icon(Icons.local_fire_department, color: AppTheme.luxeGold, size: 14),
                        SizedBox(width: 4),
                        Text('STUDIO & REHAB MODE', style: TextStyle(color: AppTheme.luxeGold, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('TRAINING & REHAB PROTOCOLS', style: TextStyle(
                color: AppTheme.textDarkPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5,
              )),
              const SizedBox(height: 4),
              const Text('Therapeutic rehab for paralysis, medical health issues, and elite performance conditioning.', style: TextStyle(
                color: AppTheme.textDarkSecondary, fontSize: 13, height: 1.4,
              )),
              const SizedBox(height: 16),

              // ── SPECIALIZED MEDICAL & REHAB HUB QUICK ACCESS ────────────────
              _buildClinicalRehabHub(),
              const SizedBox(height: 16),

              // ── Mode Switcher: Curated Plans vs Exercise Modules ────────────────
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
                        onTap: () => setState(() {
                          _workoutMode = 0;
                          _selectedCategory = 'All';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _workoutMode == 0 ? AppTheme.luxeGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 14, color: _workoutMode == 0 ? Colors.black : AppTheme.textDarkSecondary),
                              const SizedBox(width: 6),
                              Text('Curated Plans (${HealthData.curatedWorkoutPlans.length})', style: TextStyle(
                                color: _workoutMode == 0 ? Colors.black : AppTheme.textDarkSecondary,
                                fontSize: 11.5, fontWeight: FontWeight.bold,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _workoutMode = 1;
                          _selectedCategory = 'All';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _workoutMode == 1 ? AppTheme.luxeGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center_rounded, size: 14, color: _workoutMode == 1 ? Colors.black : AppTheme.textDarkSecondary),
                              const SizedBox(width: 6),
                              Text('Exercise Modules (${HealthData.sampleExercises.length})', style: TextStyle(
                                color: _workoutMode == 1 ? Colors.black : AppTheme.textDarkSecondary,
                                fontSize: 11.5, fontWeight: FontWeight.bold,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _workoutMode == 0
                        ? 'Search curated plans, conditions, paralysis, or rehab...'
                        : 'Search condition, rehab, paralysis, or muscles...',
                    hintStyle: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.luxeGold, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textDarkMuted, size: 16),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category Pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: activeCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = activeCategories[i];
                    final selected = _selectedCategory == cat;
                    Color pillColor = AppTheme.luxeGold;
                    if (cat == 'Paralysis Rehab') pillColor = const Color(0xFF2DD4BF);
                    if (cat == 'Health Issues') pillColor = const Color(0xFFF43F5E);
                    if (cat == 'Strength') pillColor = const Color(0xFFF59E0B);
                    if (cat == 'Cardio') pillColor = const Color(0xFF38BDF8);
                    if (cat == 'Fat Loss') pillColor = const Color(0xFFF97316);
                    if (cat == 'Flexibility') pillColor = const Color(0xFF818CF8);
                    if (cat == 'Recovery') pillColor = const Color(0xFF34D399);
                    if (cat == 'Fitness') pillColor = const Color(0xFFEAB308);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? pillColor : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? pillColor : AppTheme.borderDark),
                          boxShadow: selected ? [BoxShadow(color: pillColor.withOpacity(0.25), blurRadius: 10)] : null,
                        ),
                        child: Text(cat, style: TextStyle(
                          color: selected ? Colors.black : AppTheme.textDarkSecondary,
                          fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_workoutMode == 0
                      ? (_selectedCategory == 'All' ? 'ALL CURATED PLANS' : _selectedCategory.toUpperCase())
                      : (_selectedCategory == 'All' ? 'ALL PROTOCOLS' : _selectedCategory.toUpperCase()),
                    style: const TextStyle(
                      color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                    ),
                  ),
                  Text(_workoutMode == 0 ? '${filteredPlans.length} PLANS' : '${filteredExercises.length} MODULES',
                    style: const TextStyle(color: AppTheme.luxeGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_workoutMode == 0)
                ...filteredPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildPlanCard(context, plan),
                ))
              else
                ...filteredExercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildExerciseCard(ex),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalRehabHub() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _workoutMode = 0;
              _selectedCategory = 'Paralysis Rehab';
              _searchQuery = '';
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0D2826), const Color(0xFF0F1E28)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2DD4BF).withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.accessible_forward_rounded, color: Color(0xFF2DD4BF), size: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2DD4BF), size: 11),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Paralysis Rehab', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('Bed ROM, Wheelchair, Stroke & SCI Protocols', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10, height: 1.2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _workoutMode = 0;
              _selectedCategory = 'Health Issues';
              _searchQuery = '';
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2A1116), const Color(0xFF1D0E19)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.healing_rounded, color: Color(0xFFF43F5E), size: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFF43F5E), size: 11),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Health Issues', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text('Cardiac, Diabetes, Spine, Arthritis & Senior', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10, height: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise ex) {
    final diffColors = {
      'Beginner': const Color(0xFF34D399),
      'Intermediate': const Color(0xFFFBBF24),
      'Advanced': const Color(0xFFF87171),
      'Gentle Care': const Color(0xFF2DD4BF),
      'Adaptive': const Color(0xFF38BDF8),
      'Neuro-Rehab': const Color(0xFFA78BFA),
      'Therapeutic': const Color(0xFFFB7185),
      'Spine Care': const Color(0xFFEAB308),
      'Joint Safe': const Color(0xFF06B6D4),
      'Metabolic': const Color(0xFF10B981),
      'Respiratory': const Color(0xFF818CF8),
      'Balance Care': const Color(0xFF14B8A6),
    };
    final diffColor = diffColors[ex.difficulty] ?? ex.accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ex.isTherapeutic
              ? ex.accentColor.withOpacity(0.35)
              : AppTheme.borderDark.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ex.conditionBadge != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ex.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ex.accentColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ex.icon, size: 12, color: ex.accentColor),
                  const SizedBox(width: 5),
                  Text(
                    ex.conditionBadge!.toUpperCase(),
                    style: TextStyle(
                      color: ex.accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ex.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ex.accentColor.withOpacity(0.3)),
                ),
                child: Icon(ex.icon, color: ex.accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.title,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          ex.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: diffColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·  ${ex.durationMinutes} MIN  ·  ${ex.caloriesBurned} KCAL',
                          style: const TextStyle(
                            color: AppTheme.textDarkMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showStartWorkoutModal(context, ex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ex.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ex.description,
            style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, height: 1.4),
          ),
          if (ex.equipmentNeeded != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.handyman_outlined, color: ex.accentColor.withOpacity(0.8), size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ex.equipmentNeeded!,
                    style: TextStyle(
                      color: ex.accentColor.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (ex.medicalPrecaution != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF161514),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ex.accentColor.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: ex.accentColor, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Safety: ${ex.medicalPrecaution}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.borderDark.withOpacity(0.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.settings_input_component, color: AppTheme.textDarkMuted, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'FOCUS: ${ex.targetMuscles.toUpperCase()}',
                  style: const TextStyle(
                    color: AppTheme.textDarkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${ex.steps.length} STAGES',
                style: TextStyle(
                  color: ex.accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, WorkoutPlan plan) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.accentColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: plan.accentColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                if (plan.conditionBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: plan.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: plan.accentColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      plan.conditionBadge!.toUpperCase(),
                      style: TextStyle(color: plan.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  const Spacer(),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDarkElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Text(
                    '${plan.durationWeeks} WEEKS · ${plan.sessionsPerWeek} SESSIONS/WK',
                    style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              plan.name,
              style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.track_changes, color: plan.accentColor, size: 14),
                const SizedBox(width: 5),
                Text(
                  'GOAL: ${plan.goal.toUpperCase()}',
                  style: TextStyle(color: plan.accentColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan.description,
              style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, height: 1.4),
            ),

            if (plan.medicalPrecaution != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161514),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: plan.accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: plan.accentColor, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan.medicalPrecaution!,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Container(height: 1, color: AppTheme.borderDark.withOpacity(0.3)),
            const SizedBox(height: 10),

            // Weekly Schedule Preview
            if (plan.weeklySchedule.isNotEmpty) ...[
              const Text('Weekly Regimen:', style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...plan.weeklySchedule.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: plan.accentColor, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(s, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 11, height: 1.2)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            // Action Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Includes ${plan.exercises.length} specialized modules',
                    style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 11),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openPlanDetailModal(context, plan),
                  icon: const Icon(Icons.fitness_center_rounded, size: 14, color: Colors.black),
                  label: const Text('View Plan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plan.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPlanDetailModal(BuildContext context, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WorkoutPlanDetailSheet(
        plan: plan,
        onStartExercise: (ex) {
          Navigator.pop(ctx);
          _showStartWorkoutModal(context, ex);
        },
      ),
    );
  }
}

// ── Workout Active Modal ──────────────────────────────────────────────────────

class _WorkoutActiveModal extends StatefulWidget {
  final Exercise exercise;
  final Function(int calories, int mins) onComplete;

  const _WorkoutActiveModal({required this.exercise, required this.onComplete});

  @override
  State<_WorkoutActiveModal> createState() => _WorkoutActiveModalState();
}

class _WorkoutActiveModalState extends State<_WorkoutActiveModal> {
  late Timer _timer;
  int _elapsed = 0;
  bool _running = true;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running && mounted) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeDisplay {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _complete() {
    _timer.cancel();
    final calBurned = (widget.exercise.caloriesBurned * (_elapsed > 0 ? _elapsed : 600) / (widget.exercise.durationMinutes * 60)).round().clamp(10, 1000);
    final mins = (_elapsed ~/ 60) > 0 ? (_elapsed ~/ 60) : 1;
    widget.onComplete(calBurned, mins);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.black, size: 20),
          const SizedBox(width: 8),
          Text('Workout Complete! Burned $calBurned kcal in $mins mins.', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
      backgroundColor: AppTheme.luxeGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final liveBurn = (widget.exercise.caloriesBurned * _elapsed / (widget.exercise.durationMinutes * 60)).round();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
            color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2),
          ))),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.exercise.title, style: const TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 17, fontWeight: FontWeight.bold,
                )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: widget.exercise.accentColor.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                child: Text('+$liveBurn kcal', style: TextStyle(color: widget.exercise.accentColor, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.exercise.medicalPrecaution != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.exercise.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.exercise.accentColor.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined, color: widget.exercise.accentColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.exercise.medicalPrecaution!,
                      style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Timer Circle
          Center(
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.luxeGold, width: 4),
                color: AppTheme.surfaceDarkElevated,
                boxShadow: [BoxShadow(color: AppTheme.luxeGold.withOpacity(0.2), blurRadius: 18)],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_timeDisplay, style: const TextStyle(
                      color: AppTheme.luxeGold, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2,
                    )),
                    Text(_running ? 'SESSION ACTIVE' : 'PAUSED', style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Exercise Routine Steps:', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${_completedSteps.length}/${widget.exercise.steps.length} done', style: const TextStyle(color: AppTheme.luxeGold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: widget.exercise.steps.length,
              itemBuilder: (ctx, i) {
                final step = widget.exercise.steps[i];
                final done = _completedSteps.contains(i);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (done) _completedSteps.remove(i); else _completedSteps.add(i);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.luxeGold.withOpacity(0.12) : AppTheme.surfaceDarkElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: done ? AppTheme.luxeGold : AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: done ? AppTheme.luxeGold : AppTheme.textDarkMuted, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(step, style: TextStyle(
                            color: done ? AppTheme.luxeGold : AppTheme.textDarkPrimary,
                            fontSize: 13,
                            decoration: done ? TextDecoration.lineThrough : null,
                          )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { setState(() => _running = !_running); },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_running ? 'Pause' : 'Resume', style: const TextStyle(color: AppTheme.textDarkSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.luxeGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Complete Session', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Workout Plan Detail Sheet ────────────────────────────────────────────────

class _WorkoutPlanDetailSheet extends StatelessWidget {
  final WorkoutPlan plan;
  final ValueChanged<Exercise> onStartExercise;

  const _WorkoutPlanDetailSheet({required this.plan, required this.onStartExercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: plan.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: plan.accentColor.withOpacity(0.4)),
                ),
                child: Text(
                  (plan.conditionBadge ?? plan.category).toUpperCase(),
                  style: TextStyle(color: plan.accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                '${plan.durationWeeks} WEEKS',
                style: TextStyle(color: plan.accentColor, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(plan.name, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(plan.description, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 12, height: 1.4)),

          if (plan.medicalPrecaution != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: plan.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: plan.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services_outlined, color: plan.accentColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(plan.medicalPrecaution!, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          const Text('Included Protocol Modules:', style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              itemCount: plan.exercises.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final ex = plan.exercises[i];
                return GestureDetector(
                  onTap: () => onStartExercise(ex),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: ex.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(ex.icon, color: ex.accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.title, style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text('${ex.durationMinutes} min · ${ex.caloriesBurned} kcal · ${ex.steps.length} stages',
                                style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: ex.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ex.accentColor.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: ex.accentColor, size: 14),
                              const SizedBox(width: 3),
                              Text('Start', style: TextStyle(color: ex.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

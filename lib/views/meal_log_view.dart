import 'dart:async';
import 'package:flutter/material.dart';
import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../data/food_database.dart';
import '../services/firestore_service.dart';

class MealLogView extends StatefulWidget {
  final UserVitals vitals;
  final DateTime date;

  const MealLogView({Key? key, required this.vitals, required this.date}) : super(key: key);

  @override
  State<MealLogView> createState() => _MealLogViewState();
}

class _MealLogViewState extends State<MealLogView> {
  static const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  static const mealIcons = [Icons.wb_sunny_outlined, Icons.wb_cloudy_outlined, Icons.nightlight_outlined, Icons.cookie_outlined];
  StreamSubscription<DailyLog>? _logSub;

  @override
  void initState() {
    super.initState();
    _logSub = FirestoreService().streamDailyLog(widget.date).listen((liveLog) {
      if (mounted) {
        final current = widget.vitals.getLog(widget.date);
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
    super.dispose();
  }

  String get _key {
    final d = widget.date;
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  DailyLog get _log => widget.vitals.getLog(widget.date);

  void _openAddFood(String mealType) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(
        mealType: mealType,
        onAdd: (entry) {
          setState(() => _log.meals.add(entry));
          FirestoreService().addMealEntry(widget.date, entry);
        },
      ),
    );
    setState(() {});
  }

  void _removeEntry(MealEntry entry) {
    setState(() => _log.meals.remove(entry));
    FirestoreService().removeMealEntry(widget.date, entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final log = _log;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.luxeGold, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meal Log', style: TextStyle(
          color: AppTheme.textDarkPrimary, fontSize: 17, fontWeight: FontWeight.bold,
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.luxeGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.luxeGold.withOpacity(0.3)),
              ),
              child: Text(
                '${log.totalCaloriesConsumed} kcal',
                style: const TextStyle(color: AppTheme.luxeGold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Macro Summary Bar ──────────────────────────────────────────
          _buildMacroSummaryBar(log),
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              itemCount: mealTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildMealSection(mealTypes[i], mealIcons[i], log),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummaryBar(DailyLog log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          _macroItem('Protein', '${log.totalProtein.toInt()}g', const Color(0xFF818CF8)),
          _divider(),
          _macroItem('Carbs', '${log.totalCarbs.toInt()}g', const Color(0xFFFBBF24)),
          _divider(),
          _macroItem('Fat', '${log.totalFat.toInt()}g', const Color(0xFFF87171)),
          _divider(),
          _macroItem('Fiber', '${log.meals.fold(0.0, (s, m) => s + m.fiber).toStringAsFixed(1)}g', const Color(0xFF34D399)),
        ],
      ),
    );
  }

  Widget _macroItem(String label, String val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 24, color: AppTheme.borderDark);

  Widget _buildMealSection(String mealType, IconData icon, DailyLog log) {
    final entries = log.meals.where((m) => m.mealType == mealType).toList();
    final totalCal = entries.fold(0, (s, e) => s + e.calories);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.luxeGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: AppTheme.luxeGold, size: 16),
                ),
                const SizedBox(width: 10),
                Text(mealType, style: const TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.bold,
                )),
                const Spacer(),
                if (totalCal > 0)
                  Text('$totalCal kcal', style: const TextStyle(
                    color: AppTheme.luxeGold, fontSize: 12, fontWeight: FontWeight.w600,
                  )),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const Divider(color: AppTheme.borderDark, height: 1),
            ...entries.map((e) => _buildFoodEntryRow(e)),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text('Nothing logged yet.', style: const TextStyle(
                color: AppTheme.textDarkMuted, fontSize: 12,
              )),
            ),
          const Divider(color: AppTheme.borderDark, height: 1),
          InkWell(
            onTap: () => _openAddFood(mealType),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppTheme.luxeGold, size: 17),
                  const SizedBox(width: 8),
                  Text('Add food to $mealType', style: const TextStyle(
                    color: AppTheme.luxeGold, fontSize: 13, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodEntryRow(MealEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.food.name, style: const TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.w600,
                )),
                Text('${entry.displayPortion} · ${entry.food.brand}', style: const TextStyle(
                  color: AppTheme.textDarkMuted, fontSize: 11,
                )),
              ],
            ),
          ),
          Text('${entry.calories} kcal', style: const TextStyle(
            color: AppTheme.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w600,
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeEntry(entry),
            child: const Icon(Icons.close, color: AppTheme.textDarkMuted, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Add Food Bottom Sheet ─────────────────────────────────────────────────────

class _AddFoodSheet extends StatefulWidget {
  final String mealType;
  final Function(MealEntry) onAdd;

  const _AddFoodSheet({required this.mealType, required this.onAdd});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  String _query = '';
  FoodDbItem? _selected;
  // We store total grams directly now
  double _grams = 100;
  String? _selectedUnit;
  final TextEditingController _gramCtrl = TextEditingController();
  bool _editingGrams = false;

  // Gram presets for the roller (10, 15, 20, 25, 30, 40, 50, etc.)
  static const List<double> _gramPresets = [10, 15, 20, 25, 30, 40, 50, 75, 100, 150, 200, 250, 300, 400, 500];

  List<FoodDbItem> get _results => FoodDatabase.search(_query);

  @override
  void dispose() {
    _gramCtrl.dispose();
    super.dispose();
  }

  void _selectFood(FoodDbItem food) {
    setState(() {
      _selected = food;
      _grams = food.defaultServingGrams;
      _selectedUnit = food.defaultUnit;
      _gramCtrl.text = _grams.toInt().toString();
    });
  }

  double _totalGrams() {
    if (_selected == null || _selectedUnit == null) return _grams;
    if (_selectedUnit == 'g' || _selectedUnit == 'ml') return _grams;
    return _grams;
  }

  void _confirm() {
    if (_selected == null) return;
    final g = _totalGrams();
    widget.onAdd(MealEntry(
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      food: _selected!,
      servingGrams: g,
      quantity: 1.0,
      unit: 'g',
      mealType: widget.mealType,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add to ${widget.mealType}', style: const TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.bold,
                )),
                TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textDarkMuted))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search food (e.g. Oats, Chicken, Dal...)',
                hintStyle: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textDarkMuted, size: 18),
                filled: true,
                fillColor: AppTheme.surfaceDarkElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.luxeGold),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_selected != null) _buildServingEditor(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.borderDark, height: 1),
              itemBuilder: (ctx, i) => _buildFoodRow(_results[i]),
            ),
          ),
          if (_selected != null) _buildConfirmBar(),
        ],
      ),
    );
  }

  Widget _buildFoodRow(FoodDbItem food) {
    final isSelected = _selected?.id == food.id;
    final kcal = food.defaultCalories;
    return InkWell(
      onTap: () => _selectFood(food),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: isSelected ? AppTheme.luxeGold.withOpacity(0.06) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(food.name, style: TextStyle(
                        color: isSelected ? AppTheme.luxeGold : AppTheme.textDarkPrimary,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      )),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, color: AppTheme.luxeGold, size: 14),
                      ],
                    ],
                  ),
                  Text('${food.brand} · ${food.defaultServingGrams.toInt()} ${food.defaultUnit}',
                    style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$kcal kcal', style: const TextStyle(
                  color: AppTheme.textDarkPrimary, fontSize: 12, fontWeight: FontWeight.bold,
                )),
                Text('P ${food.defaultProtein.toStringAsFixed(0)}g · C ${food.defaultCarbs.toStringAsFixed(0)}g · F ${food.defaultFat.toStringAsFixed(0)}g',
                  style: const TextStyle(color: AppTheme.textDarkMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServingEditor() {
    if (_selected == null) return const SizedBox();
    final g = _grams;
    final cal = ((_selected!.caloriesPer100g * g) / 100).round();
    final prot = ((_selected!.proteinPer100g * g) / 100);
    final carb = ((_selected!.carbsPer100g * g) / 100);
    final fat = ((_selected!.fatPer100g * g) / 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.luxeGold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.luxeGold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name + calorie preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_selected!.name, style: const TextStyle(
                  color: AppTheme.luxeGold, fontSize: 13, fontWeight: FontWeight.bold,
                ), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.luxeGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$cal kcal',
                  style: const TextStyle(color: AppTheme.luxeGold, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Macro pills
          Row(
            children: [
              _macroPill('P', prot, const Color(0xFF818CF8)),
              const SizedBox(width: 8),
              _macroPill('C', carb, const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _macroPill('F', fat, const Color(0xFFF87171)),
            ],
          ),
          const SizedBox(height: 14),
          // GRAMS LABEL
          const Text('How many grams?', style: TextStyle(
            color: AppTheme.textDarkSecondary, fontSize: 12, letterSpacing: 0.5,
          )),
          const SizedBox(height: 8),
          // Gram input row: [-] [tappable gram display / text field] [+]
          Row(
            children: [
              // Minus 5g
              _stepBtn(Icons.remove, () {
                setState(() {
                  _grams = (_grams - 5).clamp(5, 2000);
                  _gramCtrl.text = _grams.toInt().toString();
                });
              }),
              const SizedBox(width: 10),
              // Gram display — tap to type manually
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _editingGrams = true);
                    _gramCtrl.text = _grams.toInt().toString();
                    _gramCtrl.selection = TextSelection(
                      baseOffset: 0, extentOffset: _gramCtrl.text.length);
                  },
                  child: _editingGrams
                    ? TextField(
                        controller: _gramCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.luxeGold, fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          suffixText: 'g',
                          suffixStyle: TextStyle(color: AppTheme.textDarkMuted, fontSize: 18),
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() => _grams = parsed.clamp(1, 5000));
                          }
                        },
                        onSubmitted: (_) => setState(() => _editingGrams = false),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.luxeGold.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.surfaceDark,
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: '${_grams.toInt()}',
                              style: const TextStyle(color: AppTheme.luxeGold, fontSize: 28, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' g',
                              style: TextStyle(color: AppTheme.textDarkMuted, fontSize: 16)),
                          ]),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              // Plus 5g
              _stepBtn(Icons.add, () {
                setState(() {
                  _grams = (_grams + 5).clamp(5, 2000);
                  _gramCtrl.text = _grams.toInt().toString();
                });
              }),
            ],
          ),
          const SizedBox(height: 12),
          // Quick-preset gram chips roller
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _gramPresets.map((preset) {
                final isActive = (_grams - preset).abs() < 0.5;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _grams = preset;
                      _gramCtrl.text = preset.toInt().toString();
                      _editingGrams = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.luxeGold : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppTheme.luxeGold : AppTheme.borderDark,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Text('${preset.toInt()}g',
                      style: TextStyle(
                        color: isActive ? Colors.black : AppTheme.textDarkSecondary,
                        fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      )),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String label, double val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: ${val.toStringAsFixed(1)}g',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Icon(icon, color: AppTheme.luxeGold, size: 20),
      ),
    );
  }

  Widget _buildConfirmBar() {
    if (_selected == null) return const SizedBox();
    final g = _grams;
    final cal = ((_selected!.caloriesPer100g * g) / 100).round();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: ElevatedButton.icon(
        onPressed: _confirm,
        icon: const Icon(Icons.check, size: 18, color: Colors.black),
        label: Text('Add ${_grams.toInt()}g · $cal kcal to ${widget.mealType}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.luxeGold,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}



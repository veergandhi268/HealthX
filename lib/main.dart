import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'models/health_models.dart';
import 'views/home_view.dart';
import 'views/workouts_view.dart';
import 'views/plans_view.dart';
import 'views/analytics_view.dart';
import 'views/splash_view.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBiOqucNi6RchOvt-CBbKy_10vicPtsapk",
      authDomain: "healthx-1d56f.firebaseapp.com",
      projectId: "healthx-1d56f",
      storageBucket: "healthx-1d56f.firebasestorage.app",
      messagingSenderId: "620758702933",
      appId: "1:620758702933:web:f3e351b96b3dd718c4addc",
      measurementId: "G-0MT982DNMS",
    ),
  );
  await FirestoreService().initLocalCache();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const HealthXApp());
}

class SmoothAppScrollBehavior extends MaterialScrollBehavior {
  const SmoothAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class HealthXApp extends StatelessWidget {
  const HealthXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthX – Premium Fitness Tracker',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const SmoothAppScrollBehavior(),
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashView(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  late UserVitals _vitals;
  StreamSubscription<DailyLog>? _todayLogSub;
  Timer? _dayRolloverTimer;
  late String _activeDateKey;

  @override
  void initState() {
    super.initState();
    _vitals = FirestoreService().cachedVitals;
    _activeDateKey = FirestoreService().formatDateKey(DateTime.now());
    _initUserData();
    _startDayRolloverTimer();
  }

  Future<void> _initUserData() async {
    final vitals = await FirestoreService().loadOrCreateUserProfile();
    if (mounted) {
      setState(() {
        _vitals.clearLogs();
        _vitals.email = vitals.email;
        _vitals.activeSubscriptionId = vitals.activeSubscriptionId;
        _vitals.age = vitals.age;
        _vitals.gender = vitals.gender;
        _vitals.activityLevel = vitals.activityLevel;
        _vitals.goal = vitals.goal;
        _vitals.targetCalories = vitals.targetCalories;
        _vitals.stepsTarget = vitals.stepsTarget;
        _vitals.waterTargetMl = vitals.waterTargetMl;
        _vitals.activeMinutes = vitals.activeMinutes;
        _vitals.heartRateBpm = vitals.heartRateBpm;
        _vitals.startingWeightKg = vitals.startingWeightKg;
        _vitals.currentWeightKg = vitals.currentWeightKg;
        _vitals.targetWeightKg = vitals.targetWeightKg;
        _vitals.heightCm = vitals.heightCm;
      });
    }
    _subscribeTodayLog();
  }

  void _subscribeTodayLog() {
    _todayLogSub?.cancel();
    _todayLogSub = FirestoreService().streamDailyLog(DateTime.now()).listen((liveLog) {
      if (mounted) {
        final today = _vitals.todayLog;
        today.meals = liveLog.meals;
        today.waterMl = liveLog.waterMl;
        today.sleepMinutes = liveLog.sleepMinutes;
        today.steps = liveLog.steps;
        today.caloriesBurned = liveLog.caloriesBurned;
        today.weightKg = liveLog.weightKg;
        setState(() {});
      }
    });
  }

  void _startDayRolloverTimer() {
    _dayRolloverTimer?.cancel();
    _dayRolloverTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final nowKey = FirestoreService().formatDateKey(DateTime.now());
      if (nowKey != _activeDateKey) {
        _activeDateKey = nowKey;
        FirestoreService().checkAndHandleDayRollover();
        _subscribeTodayLog();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _todayLogSub?.cancel();
    _dayRolloverTimer?.cancel();
    super.dispose();
  }

  void _onWorkoutCompleted(int calories, int mins) {
    setState(() {
      _vitals.todayLog.caloriesBurned += calories;
      _vitals.todayLog.steps += (mins * 100);
    });
    FirestoreService().logWorkoutCompleted(
      date: DateTime.now(),
      calories: calories,
      durationMinutes: mins,
    );
  }

  void _onRefresh() => setState(() {});

  int get _stackIndex {
    switch (_currentIndex) {
      case 0: return 0;
      case 1: return 1;
      case 3: return 2;
      case 4: return 3;
      default: return 0;
    }
  }

  void _openQuickLog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _QuickLogSheet(vitals: _vitals, onUpdate: _onRefresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadedTabs.add(_stackIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: IndexedStack(
            index: _stackIndex,
            children: [
              HomeView(
                vitals: _vitals,
                onRefresh: _onRefresh,
                onNavigateToPlans: () => setState(() {
                  _currentIndex = 3;
                  _loadedTabs.add(2);
                }),
              ),
              _loadedTabs.contains(1)
                  ? WorkoutsView(
                      isDarkMode: true,
                      onWorkoutCompleted: _onWorkoutCompleted,
                    )
                  : const SizedBox.shrink(),
              _loadedTabs.contains(2)
                  ? PlansView(vitals: _vitals)
                  : const SizedBox.shrink(),
              _loadedTabs.contains(3)
                  ? AnalyticsView(
                      vitals: _vitals,
                      isDarkMode: true,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildBottomNav(),
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFAB() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openQuickLog,
        child: Container(
          width: 58, height: 58,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.luxeGoldDark, AppTheme.luxeGold],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppTheme.luxeGold.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.fitness_center_rounded, 'Workouts'),
              const SizedBox(width: 60), // FAB space
              _navItem(3, Icons.book_outlined, 'Plans'),
              _navItem(4, Icons.bar_chart_rounded, 'Analytics'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _currentIndex = index;
            _loadedTabs.add(_stackIndex);
          }),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? AppTheme.luxeGold : AppTheme.textDarkMuted, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(
                color: isActive ? AppTheme.luxeGold : AppTheme.textDarkMuted,
                fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              )),
              if (isActive) ...[
                const SizedBox(height: 3),
                Container(width: 4, height: 4, decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.luxeGold,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Log Bottom Sheet ─────────────────────────────────────────────────────

class _QuickLogSheet extends StatefulWidget {
  final UserVitals vitals;
  final VoidCallback onUpdate;

  const _QuickLogSheet({required this.vitals, required this.onUpdate});

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  double _weight = 0;
  double _waterGlasses = 0;
  double _sleepHours = 0;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    final log = widget.vitals.todayLog;
    _weight = log.weightKg > 0 ? log.weightKg : widget.vitals.currentWeightKg;
    _waterGlasses = log.waterMl / 250.0;
    _sleepHours = log.sleepMinutes / 60.0;
    _steps = log.steps;
  }

  void _save() {
    final log = widget.vitals.todayLog;
    setState(() {
      log.weightKg = _weight;
      log.waterMl = (_waterGlasses * 250).round();
      log.sleepMinutes = (_sleepHours * 60).round();
      log.steps = _steps;
      widget.vitals.currentWeightKg = _weight;
    });
    widget.onUpdate();

    // Persist to Cloud Firestore
    FirestoreService().saveDailyMetrics(
      date: DateTime.now(),
      waterMl: log.waterMl,
      sleepMinutes: log.sleepMinutes,
      steps: log.steps,
      weightKg: _weight,
    );
    FirestoreService().saveUserProfile(widget.vitals);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.black, size: 18),
        SizedBox(width: 8),
        Text('Logged successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: AppTheme.luxeGold, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quick Log', style: TextStyle(
                color: AppTheme.textDarkPrimary, fontSize: 18, fontWeight: FontWeight.bold,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.luxeGold.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.luxeGold.withOpacity(0.3)),
                ),
                child: const Text('Today', style: TextStyle(color: AppTheme.luxeGold, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weight
          _logRow(
            icon: Icons.monitor_weight_outlined, label: 'Weight',
            value: '${_weight.toStringAsFixed(1)} kg',
            color: AppTheme.luxeGold,
            slider: Slider(
              value: _weight.clamp(40, 150), min: 40, max: 150, divisions: 110,
              activeColor: AppTheme.luxeGold, inactiveColor: AppTheme.borderDark,
              onChanged: (v) => setState(() => _weight = double.parse(v.toStringAsFixed(1))),
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 20),

          // Water
          _logRow(
            icon: Icons.water_drop, label: 'Water',
            value: '${_waterGlasses.toInt()} glasses (${(_waterGlasses * 0.25).toStringAsFixed(1)} L)',
            color: const Color(0xFF38BDF8),
            slider: Slider(
              value: _waterGlasses.clamp(0, 20), min: 0, max: 20, divisions: 20,
              activeColor: const Color(0xFF38BDF8), inactiveColor: AppTheme.borderDark,
              onChanged: (v) => setState(() => _waterGlasses = v.roundToDouble()),
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 20),

          // Sleep
          _logRow(
            icon: Icons.bedtime, label: 'Sleep',
            value: '${_sleepHours.toStringAsFixed(1)} hours',
            color: const Color(0xFFA78BFA),
            slider: Slider(
              value: _sleepHours.clamp(0, 12), min: 0, max: 12, divisions: 24,
              activeColor: const Color(0xFFA78BFA), inactiveColor: AppTheme.borderDark,
              onChanged: (v) => setState(() => _sleepHours = (v * 2).round() / 2),
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 20),

          // Steps
          _logRow(
            icon: Icons.directions_walk, label: 'Steps',
            value: '$_steps steps',
            color: const Color(0xFF34D399),
            slider: Slider(
              value: _steps.clamp(0, 20000).toDouble(), min: 0, max: 20000, divisions: 200,
              activeColor: const Color(0xFF34D399), inactiveColor: AppTheme.borderDark,
              onChanged: (v) => setState(() => _steps = (v / 100).round() * 100),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: Colors.black, size: 18),
              label: const Text('Save All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.luxeGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logRow({required IconData icon, required String label, required String value, required Color color, required Widget slider}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        slider,
      ],
    );
  }
}

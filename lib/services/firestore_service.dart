import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';
import '../data/food_database.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  UserVitals? _cachedVitals;
  DailyLog? _cachedTodayLog;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = currentUid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>>? _dailyLogDoc(DateTime date) {
    final userDoc = _userDoc;
    if (userDoc == null) return null;
    return userDoc.collection('daily_logs').doc(formatDateKey(date));
  }

  // ── USER-SCOPED & DATE-SCOPED CACHE KEYS ─────────────────────────────────────

  String _userKey(String key) {
    final uid = currentUid;
    return uid != null ? 'u_${uid}_$key' : 'u_guest_$key';
  }

  String _dailyMetricKey(DateTime date, String metric) {
    final dateKey = formatDateKey(date);
    return _userKey('${dateKey}_$metric');
  }

  void _cleanLegacyGlobalKeys() {
    _prefs?.remove('cached_sub');
    _prefs?.remove('cached_email');
    _prefs?.remove('cached_weight');
    _prefs?.remove('cached_targetCalories');
    _prefs?.remove('cached_waterTarget');
    _prefs?.remove('cached_today_water');
    _prefs?.remove('cached_today_steps');
    _prefs?.remove('cached_today_sleep');
    _prefs?.remove('cached_today_burned');
    // Note: do NOT remove cached_displayName here — it's user-scoped
  }

  /// Returns the cached display name, falling back through name → email → 'HealthX Member'
  String get cachedDisplayName {
    final user = FirebaseAuth.instance.currentUser;
    // 1. Try live Firebase Auth displayName first
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      // Also persist it for next time
      _prefs?.setString(_userKey('cached_displayName'), user.displayName!);
      return user.displayName!;
    }
    // 2. Fall back to SharedPreferences cache
    final cached = _prefs?.getString(_userKey('cached_displayName'));
    if (cached != null && cached.isNotEmpty) return cached;
    // 3. Fall back to email prefix
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'HealthX Member';
  }

  // ── INSTANT LOCAL CACHING ───────────────────────────────────────────────────

  DailyLog _getOrInitTodayLog() {
    final now = DateTime.now();
    final todayKey = formatDateKey(now);
    if (_cachedTodayLog != null && formatDateKey(_cachedTodayLog!.date) == todayKey) {
      return _cachedTodayLog!;
    }

    final lastActiveDate = _prefs?.getString(_userKey('last_active_date'));
    if (lastActiveDate == todayKey) {
      final todayWater = _prefs?.getInt(_dailyMetricKey(now, 'water')) ?? 0;
      final todaySteps = _prefs?.getInt(_dailyMetricKey(now, 'steps')) ?? 0;
      final todaySleep = _prefs?.getInt(_dailyMetricKey(now, 'sleep')) ?? 0;
      final todayBurned = _prefs?.getInt(_dailyMetricKey(now, 'burned')) ?? 0;
      final todayWeight = _prefs?.getDouble(_dailyMetricKey(now, 'weight')) ?? 0.0;
      _cachedTodayLog = DailyLog(
        date: now,
        waterMl: todayWater,
        steps: todaySteps,
        sleepMinutes: todaySleep,
        caloriesBurned: todayBurned,
        weightKg: todayWeight,
      );
    } else {
      // New day or fresh user: clean 0s!
      _cachedTodayLog = DailyLog(date: now);
      _prefs?.setString(_userKey('last_active_date'), todayKey);
    }
    return _cachedTodayLog!;
  }

  /// Synchronously returns cached vitals with zero delay
  UserVitals get cachedVitals {
    if (_cachedVitals != null) return _cachedVitals!;
    final user = FirebaseAuth.instance.currentUser;
    final cachedSub = _prefs?.getString(_userKey('cached_sub')) ?? 'free';
    final cachedEmail = _prefs?.getString(_userKey('cached_email')) ?? (user?.email ?? 'member@healthx.com');
    final currentWeight = _prefs?.getDouble(_userKey('cached_weight')) ?? 70.0;
    final startingWeight = _prefs?.getDouble(_userKey('cached_startingWeight')) ?? currentWeight;
    final targetWeight = _prefs?.getDouble(_userKey('cached_targetWeight')) ?? 65.0;
    final height = _prefs?.getDouble(_userKey('cached_height')) ?? 175.0;
    final age = _prefs?.getInt(_userKey('cached_age')) ?? 26;
    final gender = _prefs?.getString(_userKey('cached_gender')) ?? 'Male';
    final activityLevel = _prefs?.getString(_userKey('cached_activityLevel')) ?? 'Moderately Active';
    final goal = _prefs?.getString(_userKey('cached_goal')) ?? 'Weight Loss';
    final targetCalories = _prefs?.getInt(_userKey('cached_targetCalories')) ?? 2100;
    final stepsTarget = _prefs?.getInt(_userKey('cached_stepsTarget')) ?? 10000;
    final waterTarget = _prefs?.getInt(_userKey('cached_waterTarget')) ?? 3000;
    final activeMinutes = _prefs?.getInt(_userKey('cached_activeMinutes')) ?? 45;
    final heartRateBpm = _prefs?.getInt(_userKey('cached_heartRateBpm')) ?? 72;

    _cachedVitals = UserVitals(
      email: cachedEmail,
      activeSubscriptionId: cachedSub,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      targetCalories: targetCalories,
      stepsTarget: stepsTarget,
      waterTargetMl: waterTarget,
      activeMinutes: activeMinutes,
      heartRateBpm: heartRateBpm,
      startingWeightKg: startingWeight,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      heightCm: height,
    );
    _cachedVitals!.dailyLogs[formatDateKey(DateTime.now())] = _getOrInitTodayLog();
    return _cachedVitals!;
  }

  DailyLog? get cachedTodayLog => _cachedTodayLog;

  /// Pre-loads SharedPreferences into memory so all reads are instant
  Future<void> initLocalCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _cleanLegacyGlobalKeys();

      final now = DateTime.now();
      final todayKey = formatDateKey(now);
      final lastDate = _prefs?.getString(_userKey('last_active_date'));

      final sub = _prefs?.getString(_userKey('cached_sub')) ?? 'free';
      final email = _prefs?.getString(_userKey('cached_email')) ?? (FirebaseAuth.instance.currentUser?.email ?? 'member@healthx.com');
      final currentWeight = _prefs?.getDouble(_userKey('cached_weight')) ?? 70.0;
      final startingWeight = _prefs?.getDouble(_userKey('cached_startingWeight')) ?? currentWeight;
      final targetWeight = _prefs?.getDouble(_userKey('cached_targetWeight')) ?? 65.0;
      final height = _prefs?.getDouble(_userKey('cached_height')) ?? 175.0;
      final age = _prefs?.getInt(_userKey('cached_age')) ?? 26;
      final gender = _prefs?.getString(_userKey('cached_gender')) ?? 'Male';
      final activityLevel = _prefs?.getString(_userKey('cached_activityLevel')) ?? 'Moderately Active';
      final goal = _prefs?.getString(_userKey('cached_goal')) ?? 'Weight Loss';
      final targetCalories = _prefs?.getInt(_userKey('cached_targetCalories')) ?? 2100;
      final stepsTarget = _prefs?.getInt(_userKey('cached_stepsTarget')) ?? 10000;
      final waterTarget = _prefs?.getInt(_userKey('cached_waterTarget')) ?? 3000;
      final activeMinutes = _prefs?.getInt(_userKey('cached_activeMinutes')) ?? 45;
      final heartRateBpm = _prefs?.getInt(_userKey('cached_heartRateBpm')) ?? 72;

      if (lastDate == todayKey) {
        final todayWater = _prefs?.getInt(_dailyMetricKey(now, 'water')) ?? 0;
        final todaySteps = _prefs?.getInt(_dailyMetricKey(now, 'steps')) ?? 0;
        final todaySleep = _prefs?.getInt(_dailyMetricKey(now, 'sleep')) ?? 0;
        final todayBurned = _prefs?.getInt(_dailyMetricKey(now, 'burned')) ?? 0;
        final todayWeight = _prefs?.getDouble(_dailyMetricKey(now, 'weight')) ?? currentWeight;

        _cachedTodayLog = DailyLog(
          date: now,
          waterMl: todayWater,
          steps: todaySteps,
          sleepMinutes: todaySleep,
          caloriesBurned: todayBurned,
          weightKg: todayWeight,
        );
      } else {
        // Different day! Fresh start for today: 0 water, 0 steps, 0 sleep, 0 calories
        _cachedTodayLog = DailyLog(date: now);
        _prefs?.setString(_userKey('last_active_date'), todayKey);
      }

      _cachedVitals = UserVitals(
        email: email,
        activeSubscriptionId: sub,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
        targetCalories: targetCalories,
        stepsTarget: stepsTarget,
        waterTargetMl: waterTarget,
        activeMinutes: activeMinutes,
        heartRateBpm: heartRateBpm,
        startingWeightKg: startingWeight,
        currentWeightKg: currentWeight,
        targetWeightKg: targetWeight,
        heightCm: height,
      );
      _cachedVitals!.dailyLogs[todayKey] = _cachedTodayLog!;
    } catch (e) {
      debugPrint('Error initLocalCache: $e');
    }
  }

  void _saveToLocalCache(UserVitals vitals) {
    _cachedVitals = vitals;
    _prefs?.setString(_userKey('cached_sub'), vitals.activeSubscriptionId);
    _prefs?.setString(_userKey('cached_email'), vitals.email);
    _prefs?.setDouble(_userKey('cached_weight'), vitals.currentWeightKg);
    _prefs?.setDouble(_userKey('cached_startingWeight'), vitals.startingWeightKg);
    _prefs?.setDouble(_userKey('cached_targetWeight'), vitals.targetWeightKg);
    _prefs?.setDouble(_userKey('cached_height'), vitals.heightCm);
    _prefs?.setInt(_userKey('cached_age'), vitals.age);
    _prefs?.setString(_userKey('cached_gender'), vitals.gender);
    _prefs?.setString(_userKey('cached_activityLevel'), vitals.activityLevel);
    _prefs?.setString(_userKey('cached_goal'), vitals.goal);
    _prefs?.setInt(_userKey('cached_targetCalories'), vitals.targetCalories);
    _prefs?.setInt(_userKey('cached_stepsTarget'), vitals.stepsTarget);
    _prefs?.setInt(_userKey('cached_waterTarget'), vitals.waterTargetMl);
    _prefs?.setInt(_userKey('cached_activeMinutes'), vitals.activeMinutes);
    _prefs?.setInt(_userKey('cached_heartRateBpm'), vitals.heartRateBpm);
    // Persist display name so it is available immediately after refresh
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _prefs?.setString(_userKey('cached_displayName'), user.displayName!);
    }
  }

  void _saveTodayMetricsToLocalCache({
    DateTime? date,
    int? waterMl,
    int? sleepMinutes,
    int? steps,
    int? caloriesBurned,
    double? weightKg,
  }) {
    final d = date ?? DateTime.now();
    final todayKey = formatDateKey(DateTime.now());
    final dKey = formatDateKey(d);

    if (waterMl != null) _prefs?.setInt(_dailyMetricKey(d, 'water'), waterMl);
    if (sleepMinutes != null) _prefs?.setInt(_dailyMetricKey(d, 'sleep'), sleepMinutes);
    if (steps != null) _prefs?.setInt(_dailyMetricKey(d, 'steps'), steps);
    if (caloriesBurned != null) _prefs?.setInt(_dailyMetricKey(d, 'burned'), caloriesBurned);
    if (weightKg != null) {
      _prefs?.setDouble(_dailyMetricKey(d, 'weight'), weightKg);
      _prefs?.setDouble(_userKey('cached_weight'), weightKg);
    }

    if (dKey == todayKey) {
      _prefs?.setString(_userKey('last_active_date'), todayKey);
    }
  }

  /// Clears in-memory caches and global legacy keys on sign-out
  Future<void> signOut() async {
    _cachedVitals = null;
    _cachedTodayLog = null;
    _cleanLegacyGlobalKeys();
  }

  /// Called after user signs in to ensure clean state and load/create fresh profile
  Future<void> onUserSignedIn() async {
    _cachedVitals = null;
    _cachedTodayLog = null;
    _cleanLegacyGlobalKeys();
    await initLocalCache();
    await loadOrCreateUserProfile();
  }

  /// Checks whether a new calendar day has started.
  /// If so, resets today's in-memory log so the new day starts completely fresh.
  bool checkAndHandleDayRollover() {
    final now = DateTime.now();
    final todayKey = formatDateKey(now);
    final lastDate = _prefs?.getString(_userKey('last_active_date'));
    if (lastDate != null && lastDate != todayKey) {
      _cachedTodayLog = DailyLog(date: now);
      if (_cachedVitals != null) {
        _cachedVitals!.dailyLogs[todayKey] = _cachedTodayLog!;
      }
      _prefs?.setString(_userKey('last_active_date'), todayKey);
      return true;
    }
    return false;
  }

  // ── USER PROFILE ─────────────────────────────────────────────────────────────

  /// Loads the user's profile from Firestore. If it does not exist, creates it
  /// using Google account info and initial vitals with NO subscription ('free').
  Future<UserVitals> loadOrCreateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final docRef = _userDoc;
    
    if (user == null || docRef == null) {
      return cachedVitals;
    }

    try {
      final snapshot = await docRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final vitals = UserVitals(
          email: data['email'] ?? user.email ?? 'member@healthx.com',
          activeSubscriptionId: data['activeSubscriptionId'] ?? 'free',
          age: (data['age'] as num?)?.toInt() ?? 26,
          gender: data['gender'] ?? 'Male',
          activityLevel: data['activityLevel'] ?? 'Moderately Active',
          goal: data['goal'] ?? 'Weight Loss',
          targetCalories: (data['targetCalories'] as num?)?.toInt() ?? 2100,
          stepsTarget: (data['stepsTarget'] as num?)?.toInt() ?? 10000,
          waterTargetMl: (data['waterTargetMl'] as num?)?.toInt() ?? 3000,
          activeMinutes: (data['activeMinutes'] as num?)?.toInt() ?? 45,
          heartRateBpm: (data['heartRateBpm'] as num?)?.toInt() ?? 72,
          startingWeightKg: (data['startingWeightKg'] as num?)?.toDouble() ?? 70.0,
          currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble() ?? 70.0,
          targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble() ?? 65.0,
          heightCm: (data['heightCm'] as num?)?.toDouble() ?? 175.0,
        );
        _saveToLocalCache(vitals);
        return vitals;
      } else {
        // Initial setup for new user:
        // 1. Explicitly NO subscription ('free')
        // 2. Explicitly NO activity logs (all 0s)
        final cachedStart = _prefs?.getDouble(_userKey('cached_startingWeight')) ?? 70.0;
        final cachedCurr = _prefs?.getDouble(_userKey('cached_weight')) ?? cachedStart;
        final cachedTarget = _prefs?.getDouble(_userKey('cached_targetWeight')) ?? 65.0;
        final cachedHeight = _prefs?.getDouble(_userKey('cached_height')) ?? 175.0;
        final cachedAge = _prefs?.getInt(_userKey('cached_age')) ?? 26;
        final cachedGender = _prefs?.getString(_userKey('cached_gender')) ?? 'Male';
        final cachedActivity = _prefs?.getString(_userKey('cached_activityLevel')) ?? 'Moderately Active';
        final cachedGoal = _prefs?.getString(_userKey('cached_goal')) ?? 'Weight Loss';

        final defaultVitals = UserVitals(
          email: user.email ?? 'member@healthx.com',
          activeSubscriptionId: 'free',
          age: cachedAge,
          gender: cachedGender,
          activityLevel: cachedActivity,
          goal: cachedGoal,
          targetCalories: 2100,
          stepsTarget: 10000,
          waterTargetMl: 3000,
          activeMinutes: 45,
          heartRateBpm: 72,
          startingWeightKg: cachedStart,
          currentWeightKg: cachedCurr,
          targetWeightKg: cachedTarget,
          heightCm: cachedHeight,
        );
        _cachedTodayLog = DailyLog(date: DateTime.now());
        defaultVitals.dailyLogs[formatDateKey(DateTime.now())] = _cachedTodayLog!;

        _saveToLocalCache(defaultVitals);
        _saveTodayMetricsToLocalCache(
          date: DateTime.now(),
          waterMl: 0,
          sleepMinutes: 0,
          steps: 0,
          caloriesBurned: 0,
          weightKg: defaultVitals.currentWeightKg,
        );
        _prefs?.setString(_userKey('last_active_date'), formatDateKey(DateTime.now()));

        await saveUserProfile(defaultVitals);
        return defaultVitals;
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return cachedVitals;
    }
  }

  /// Saves or updates the user profile in Firestore
  Future<void> saveUserProfile(UserVitals vitals) async {
    final user = FirebaseAuth.instance.currentUser;
    final docRef = _userDoc;
    _saveToLocalCache(vitals);
    if (docRef == null) return;

    try {
      await docRef.set({
        'uid': user?.uid,
        'displayName': user?.displayName ?? 'HealthX Member',
        'email': user?.email ?? vitals.email,
        'photoURL': user?.photoURL,
        'activeSubscriptionId': vitals.activeSubscriptionId,
        'age': vitals.age,
        'gender': vitals.gender,
        'activityLevel': vitals.activityLevel,
        'goal': vitals.goal,
        'targetCalories': vitals.targetCalories,
        'stepsTarget': vitals.stepsTarget,
        'waterTargetMl': vitals.waterTargetMl,
        'activeMinutes': vitals.activeMinutes,
        'heartRateBpm': vitals.heartRateBpm,
        'startingWeightKg': vitals.startingWeightKg,
        'currentWeightKg': vitals.currentWeightKg,
        'targetWeightKg': vitals.targetWeightKg,
        'heightCm': vitals.heightCm,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  /// Updates subscription tier instantly in local cache and persists to Firestore
  Future<void> updateSubscription(String planId) async {
    _prefs?.setString(_userKey('cached_sub'), planId);
    _cachedVitals?.activeSubscriptionId = planId;
    final docRef = _userDoc;
    if (docRef == null) return;
    try {
      await docRef.set({
        'activeSubscriptionId': planId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating subscription: $e');
    }
  }

  // ── PAYMENTS & TRANSACTIONS ────────────────────────────────────────────────

  /// Records a payment transaction in users/{uid}/payments/{transactionId}
  Future<void> recordPaymentTransaction(PaymentTransaction transaction) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    try {
      await userDoc
          .collection('payments')
          .doc(transaction.id)
          .set(transaction.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording payment transaction: $e');
    }
  }

  /// Upgrades subscription atomically and logs the payment transaction
  Future<void> updateSubscriptionWithPayment({
    required String planId,
    required PaymentTransaction transaction,
  }) async {
    _prefs?.setString(_userKey('cached_sub'), planId);
    _cachedVitals?.activeSubscriptionId = planId;
    final docRef = _userDoc;
    if (docRef == null) return;

    try {
      final batch = _firestore.batch();
      batch.set(
        docRef,
        {
          'activeSubscriptionId': planId,
          'lastPaymentId': transaction.id,
          'lastPaymentAmount': transaction.amount,
          'lastPaymentDate': transaction.createdAt.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final paymentDoc = docRef.collection('payments').doc(transaction.id);
      batch.set(paymentDoc, transaction.toMap(), SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating subscription with payment: $e');
      // Fallback
      await updateSubscription(planId);
      await recordPaymentTransaction(transaction);
    }
  }

  /// Stream of past payment transactions for receipts
  Stream<List<PaymentTransaction>> streamPaymentHistory() {
    final userDoc = _userDoc;
    if (userDoc == null) return Stream.value([]);
    return userDoc
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.data()))
          .toList();
    });
  }

  /// Fetches past payment transactions once
  Future<List<PaymentTransaction>> getPaymentHistory() async {
    final userDoc = _userDoc;
    if (userDoc == null) return [];
    try {
      final snapshot = await userDoc
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  // ── DAILY LOG & MEALS ────────────────────────────────────────────────────────

  /// Stream of DailyLog for reactive UI updates
  Stream<DailyLog> streamDailyLog(DateTime date) {
    final docRef = _dailyLogDoc(date);
    final isToday = formatDateKey(date) == formatDateKey(DateTime.now());

    if (docRef == null) {
      return Stream.value(isToday ? _getOrInitTodayLog() : DailyLog(date: date));
    }

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return isToday ? _getOrInitTodayLog() : DailyLog(date: date);
      }
      final log = _parseDailyLog(date, snapshot.data()!);
      if (isToday) {
        _cachedTodayLog = log;
        _saveTodayMetricsToLocalCache(
          date: date,
          waterMl: log.waterMl,
          sleepMinutes: log.sleepMinutes,
          steps: log.steps,
          caloriesBurned: log.caloriesBurned,
          weightKg: log.weightKg,
        );
      }
      return log;
    });
  }

  /// Fetches a DailyLog once
  Future<DailyLog> getDailyLog(DateTime date) async {
    final docRef = _dailyLogDoc(date);
    final isToday = formatDateKey(date) == formatDateKey(DateTime.now());

    if (docRef == null) return isToday ? _getOrInitTodayLog() : DailyLog(date: date);

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return isToday ? _getOrInitTodayLog() : DailyLog(date: date);
      }
      final log = _parseDailyLog(date, snapshot.data()!);
      if (isToday) {
        _cachedTodayLog = log;
      }
      return log;
    } catch (e) {
      debugPrint('Error fetching daily log: $e');
      return isToday ? _getOrInitTodayLog() : DailyLog(date: date);
    }
  }

  /// Saves daily metric updates (water, sleep, steps, weight, burned calories)
  Future<void> saveDailyMetrics({
    required DateTime date,
    int? waterMl,
    int? sleepMinutes,
    int? steps,
    int? caloriesBurned,
    double? weightKg,
  }) async {
    _saveTodayMetricsToLocalCache(
      date: date,
      waterMl: waterMl,
      sleepMinutes: sleepMinutes,
      steps: steps,
      caloriesBurned: caloriesBurned,
      weightKg: weightKg,
    );

    final docRef = _dailyLogDoc(date);
    if (docRef == null) return;

    final data = <String, dynamic>{
      'date': formatDateKey(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (waterMl != null) data['waterMl'] = waterMl;
    if (sleepMinutes != null) data['sleepMinutes'] = sleepMinutes;
    if (steps != null) data['steps'] = steps;
    if (caloriesBurned != null) data['caloriesBurned'] = caloriesBurned;
    if (weightKg != null) data['weightKg'] = weightKg;

    try {
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving daily metrics: $e');
    }
  }

  /// Adds a MealEntry to the daily log
  Future<void> addMealEntry(DateTime date, MealEntry entry) async {
    final docRef = _dailyLogDoc(date);
    if (docRef == null) return;

    final entryMap = {
      'id': entry.id,
      'foodId': entry.food.id,
      'foodName': entry.food.name,
      'brand': entry.food.brand,
      'category': entry.food.category,
      'caloriesPer100g': entry.food.caloriesPer100g,
      'proteinPer100g': entry.food.proteinPer100g,
      'carbsPer100g': entry.food.carbsPer100g,
      'fatPer100g': entry.food.fatPer100g,
      'fiberPer100g': entry.food.fiberPer100g,
      'servingGrams': entry.servingGrams,
      'mealType': entry.mealType,
      'quantity': entry.quantity,
      'unit': entry.unit,
      'loggedAt': entry.loggedAt.toIso8601String(),
    };

    try {
      await docRef.set({
        'date': formatDateKey(date),
        'meals': FieldValue.arrayUnion([entryMap]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding meal entry: $e');
    }
  }

  /// Removes a MealEntry by finding and filtering out by id
  Future<void> removeMealEntry(DateTime date, String entryId) async {
    final docRef = _dailyLogDoc(date);
    if (docRef == null) return;

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) return;

      final data = snapshot.data()!;
      final rawMeals = (data['meals'] as List<dynamic>?) ?? [];
      final updatedMeals = rawMeals.where((m) => m is Map && m['id'] != entryId).toList();

      await docRef.update({
        'meals': updatedMeals,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing meal entry: $e');
    }
  }

  /// Increments workout metrics for today
  Future<void> logWorkoutCompleted({
    required DateTime date,
    required int calories,
    required int durationMinutes,
  }) async {
    final docRef = _dailyLogDoc(date);
    if (docRef == null) return;

    try {
      await docRef.set({
        'date': formatDateKey(date),
        'caloriesBurned': FieldValue.increment(calories),
        'steps': FieldValue.increment(durationMinutes * 100),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error logging workout: $e');
    }
  }

  // ── HELPER PARSERS ──────────────────────────────────────────────────────────

  DailyLog _parseDailyLog(DateTime date, Map<String, dynamic> data) {
    final mealsList = <MealEntry>[];
    if (data['meals'] is List) {
      for (final m in (data['meals'] as List)) {
        if (m is Map) {
          try {
            final foodId = m['foodId'] as String? ?? '';
            FoodDbItem food;
            final matched = FoodDatabase.items.where((f) => f.id == foodId);
            if (matched.isNotEmpty) {
              food = matched.first;
            } else {
              food = FoodDbItem(
                id: foodId,
                name: m['foodName'] as String? ?? 'Food Item',
                brand: m['brand'] as String? ?? 'Custom',
                category: m['category'] as String? ?? 'Meal',
                caloriesPer100g: (m['caloriesPer100g'] as num?)?.toInt() ?? 100,
                proteinPer100g: (m['proteinPer100g'] as num?)?.toDouble() ?? 5.0,
                carbsPer100g: (m['carbsPer100g'] as num?)?.toDouble() ?? 10.0,
                fatPer100g: (m['fatPer100g'] as num?)?.toDouble() ?? 2.0,
                fiberPer100g: (m['fiberPer100g'] as num?)?.toDouble() ?? 1.0,
                defaultUnit: m['unit'] as String? ?? 'g',
                defaultServingGrams: (m['servingGrams'] as num?)?.toDouble() ?? 100.0,
              );
            }

            mealsList.add(MealEntry(
              id: m['id'] as String? ?? UniqueKey().toString(),
              food: food,
              servingGrams: (m['servingGrams'] as num?)?.toDouble() ?? 100.0,
              mealType: m['mealType'] as String? ?? 'Lunch',
              quantity: (m['quantity'] as num?)?.toDouble() ?? 1.0,
              unit: m['unit'] as String? ?? '',
              loggedAt: m['loggedAt'] != null ? DateTime.tryParse(m['loggedAt']) : null,
            ));
          } catch (e) {
            debugPrint('Failed to parse meal: $e');
          }
        }
      }
    }

    return DailyLog(
      date: date,
      meals: mealsList,
      waterMl: (data['waterMl'] as num?)?.toInt() ?? 0,
      sleepMinutes: (data['sleepMinutes'] as num?)?.toInt() ?? 0,
      steps: (data['steps'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toInt() ?? 0,
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

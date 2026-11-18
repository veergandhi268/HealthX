import 'package:flutter/material.dart';

class FoodDbItem {
  final String id;
  final String name;
  final String brand;
  final String category;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final String defaultUnit;
  final double defaultServingGrams;

  const FoodDbItem({
    required this.id,
    required this.name,
    this.brand = 'Home Made',
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0,
    this.defaultUnit = 'g',
    this.defaultServingGrams = 100,
  });

  int get defaultCalories => ((caloriesPer100g * defaultServingGrams) / 100).round();
  double get defaultProtein => (proteinPer100g * defaultServingGrams) / 100;
  double get defaultCarbs => (carbsPer100g * defaultServingGrams) / 100;
  double get defaultFat => (fatPer100g * defaultServingGrams) / 100;
  double get defaultFiber => (fiberPer100g * defaultServingGrams) / 100;
}

class MealEntry {
  final String id;
  final FoodDbItem food;
  final double servingGrams;
  final String mealType;
  final DateTime loggedAt;
  double quantity;
  final String unit;

  MealEntry({
    required this.id,
    required this.food,
    required this.servingGrams,
    required this.mealType,
    DateTime? loggedAt,
    this.quantity = 1.0,
    this.unit = '',
  }) : loggedAt = loggedAt ?? DateTime.now();

  int get calories => ((food.caloriesPer100g * servingGrams * quantity) / 100).round();
  double get protein => (food.proteinPer100g * servingGrams * quantity) / 100;
  double get carbs => (food.carbsPer100g * servingGrams * quantity) / 100;
  double get fat => (food.fatPer100g * servingGrams * quantity) / 100;
  double get fiber => (food.fiberPer100g * servingGrams * quantity) / 100;

  String get displayPortion {
    final totalGrams = (servingGrams * quantity).round();
    final displayUnit = unit.isNotEmpty ? unit : food.defaultUnit;
    
    // If it's a raw weight measurement (grams, ml)
    if (displayUnit == 'g' || displayUnit == 'ml') {
      return '$totalGrams $displayUnit';
    }
    
    final qtyStr = quantity == quantity.toInt() ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
    return '$qtyStr $displayUnit ($totalGrams g)';
  }
}

class DailyLog {
  final DateTime date;
  List<MealEntry> meals;
  double weightKg;
  int waterMl;
  int sleepMinutes;
  int steps;
  int caloriesBurned;

  DailyLog({
    required this.date,
    List<MealEntry>? meals,
    this.weightKg = 0,
    this.waterMl = 0,
    this.sleepMinutes = 0,
    this.steps = 0,
    this.caloriesBurned = 0,
  }) : meals = meals ?? [];

  int get totalCaloriesConsumed => meals.fold(0, (sum, m) => sum + m.calories);
  double get totalProtein => meals.fold(0.0, (s, m) => s + m.protein);
  double get totalCarbs => meals.fold(0.0, (s, m) => s + m.carbs);
  double get totalFat => meals.fold(0.0, (s, m) => s + m.fat);

  List<MealEntry> get breakfast => meals.where((m) => m.mealType == 'Breakfast').toList();
  List<MealEntry> get lunch => meals.where((m) => m.mealType == 'Lunch').toList();
  List<MealEntry> get dinner => meals.where((m) => m.mealType == 'Dinner').toList();
  List<MealEntry> get snacks => meals.where((m) => m.mealType == 'Snacks').toList();
}

class Exercise {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int caloriesBurned;
  final String targetMuscles;
  final String description;
  final List<String> steps;
  final IconData icon;
  final Color accentColor;
  final String? conditionBadge;
  final String? medicalPrecaution;
  final String? equipmentNeeded;
  final bool isTherapeutic;

  Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.targetMuscles,
    required this.description,
    required this.steps,
    required this.icon,
    required this.accentColor,
    this.conditionBadge,
    this.medicalPrecaution,
    this.equipmentNeeded,
    this.isTherapeutic = false,
  });
}

class WorkoutPlan {
  final String id;
  final String name;
  final String goal;
  final String difficulty;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String description;
  final List<Exercise> exercises;
  final String category;
  final String? conditionBadge;
  final String? medicalPrecaution;
  final Color accentColor;
  final List<String> weeklySchedule;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.difficulty,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    required this.description,
    required this.exercises,
    this.category = 'Fitness',
    this.conditionBadge,
    this.medicalPrecaution,
    this.accentColor = const Color(0xFFC5A059),
    this.weeklySchedule = const [],
  });
}

class DietPlan {
  final String id;
  final String name;
  final String goal;
  final String description;
  final int dailyCaloriesTarget;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final Color accentColor;
  final String category;       // 'Paralysis' | 'Health Issues' | 'General'
  final String? conditionTag;  // e.g. 'Paralysis & SCI Care'
  final List<String> mealExamples;
  final List<String> keyFoods;
  final List<Color> gradientColors;

  DietPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.description,
    required this.dailyCaloriesTarget,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.accentColor,
    this.category = 'General',
    this.conditionTag,
    this.mealExamples = const [],
    this.keyFoods = const [],
    List<Color>? gradientColors,
  }) : gradientColors = gradientColors ?? [accentColor];
}

class SubscriptionPlan {
  final String id;
  final String title;
  final String badge;
  final String priceMonthly;
  final String priceYearly;
  final String periodText;
  final String description;
  final List<String> features;
  final Color accentColor;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.badge,
    required this.priceMonthly,
    required this.priceYearly,
    required this.periodText,
    required this.description,
    required this.features,
    required this.accentColor,
    this.isPopular = false,
  });

  int get numericMonthlyPrice {
    final digits = priceMonthly.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int get numericYearlyPrice {
    final digits = priceYearly.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int priceForBilling({required bool isAnnual}) {
    return isAnnual ? numericYearlyPrice : numericMonthlyPrice;
  }

  int priceInPaise({required bool isAnnual}) {
    return priceForBilling(isAnnual: isAnnual) * 100;
  }
}

class UserVitals {
  String email;
  String activeSubscriptionId;
  int age;
  String gender;
  String activityLevel;
  String goal;
  int targetCalories;
  int stepsTarget;
  int waterTargetMl;
  int activeMinutes;
  int heartRateBpm;
  double startingWeightKg;
  double currentWeightKg;
  double targetWeightKg;
  double heightCm;
  final Map<String, DailyLog> dailyLogs;

  UserVitals({
    this.email = 'member@healthx.com',
    this.activeSubscriptionId = 'free',
    this.age = 26,
    this.gender = 'Male',
    this.activityLevel = 'Moderately Active',
    this.goal = 'Weight Loss',
    this.targetCalories = 2100,
    this.stepsTarget = 10000,
    this.waterTargetMl = 3000,
    this.activeMinutes = 45,
    this.heartRateBpm = 72,
    this.startingWeightKg = 78.0,
    this.currentWeightKg = 73.5,
    this.targetWeightKg = 68.0,
    this.heightCm = 176.0,
    Map<String, DailyLog>? dailyLogs,
  }) : dailyLogs = dailyLogs ?? {};

  void clearLogs() => dailyLogs.clear();

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DailyLog getLog(DateTime date) {
    final key = _key(date);
    return dailyLogs.putIfAbsent(key, () => DailyLog(date: date));
  }

  DailyLog get todayLog => getLog(DateTime.now());

  List<MealEntry> get loggedFoods => todayLog.meals;

  int get stepsCount => todayLog.steps;
  int get caloriesBurned => todayLog.caloriesBurned;
  int get waterIntakeMl => todayLog.waterMl;
  int get sleepMinutes => todayLog.sleepMinutes;

  int get consumedCalories => todayLog.totalCaloriesConsumed;
  int get remainingCalories => targetCalories - consumedCalories + todayLog.caloriesBurned;
  double get consumedProtein => todayLog.totalProtein;
  double get consumedCarbs => todayLog.totalCarbs;
  double get consumedFat => todayLog.totalFat;

  double get bmi {
    final h = heightCm / 100.0;
    return currentWeightKg / (h * h);
  }

  String get bmiCategory {
    final v = bmi;
    if (v < 18.5) return 'Underweight';
    if (v < 25.0) return 'Healthy Weight';
    if (v < 30.0) return 'Overweight';
    return 'Obese';
  }

  double get bmr {
    if (gender == 'Female') {
      return 10 * currentWeightKg + 6.25 * heightCm - 5 * age - 161;
    }
    return 10 * currentWeightKg + 6.25 * heightCm - 5 * age + 5;
  }

  double get activityMultiplier {
    switch (activityLevel) {
      case 'Sedentary': return 1.2;
      case 'Lightly Active': return 1.375;
      case 'Moderately Active': return 1.55;
      case 'Very Active': return 1.725;
      case 'Extra Active': return 1.9;
      default: return 1.55;
    }
  }

  double get tdee => bmr * activityMultiplier;

  int get calculatedRecommendedCalories {
    if (goal == 'Weight Loss') return (tdee - 500).round();
    if (goal == 'Muscle Gain') return (tdee + 350).round();
    return tdee.round();
  }

  double get weightLostKg {
    if (targetWeightKg > startingWeightKg) {
      return (currentWeightKg - startingWeightKg).clamp(0.0, 100.0);
    }
    return (startingWeightKg - currentWeightKg).clamp(0.0, 100.0);
  }

  double get weightRemainingKg {
    if (targetWeightKg > startingWeightKg) {
      return (targetWeightKg - currentWeightKg).clamp(0.0, 100.0);
    }
    return (currentWeightKg - targetWeightKg).clamp(0.0, 100.0);
  }
}

class PaymentTransaction {
  final String id; // e.g. pay_9aB2C3d4E5f6G7
  final String orderId; // e.g. order_8xY9Z0a1B2c3
  final String planId; // pro, elite, vip
  final String planTitle;
  final double amount; // in rupees
  final String currency;
  final String billingCycle; // monthly or yearly
  final String status; // captured, failed, pending
  final DateTime createdAt;
  final String method; // upi, card, netbanking
  final String? paymentSignature;
  final String? customerEmail;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.planId,
    required this.planTitle,
    required this.amount,
    this.currency = 'INR',
    required this.billingCycle,
    this.status = 'captured',
    DateTime? createdAt,
    this.method = 'upi',
    this.paymentSignature,
    this.customerEmail,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'planId': planId,
    'planTitle': planTitle,
    'amount': amount,
    'currency': currency,
    'billingCycle': billingCycle,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'method': method,
    'paymentSignature': paymentSignature ?? '',
    'customerEmail': customerEmail ?? '',
  };

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) => PaymentTransaction(
    id: map['id'] as String? ?? '',
    orderId: map['orderId'] as String? ?? '',
    planId: map['planId'] as String? ?? '',
    planTitle: map['planTitle'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    currency: map['currency'] as String? ?? 'INR',
    billingCycle: map['billingCycle'] as String? ?? 'monthly',
    status: map['status'] as String? ?? 'captured',
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'] as String)
        : null,
    method: map['method'] as String? ?? 'upi',
    paymentSignature: map['paymentSignature'] as String?,
    customerEmail: map['customerEmail'] as String?,
  );
}

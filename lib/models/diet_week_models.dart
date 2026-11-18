import 'package:flutter/material.dart';

class DietMealItem {
  final String type; // 'Breakfast', 'Lunch', 'Snack', 'Dinner'
  final String time; // e.g. '8:00 AM'
  final String name;
  final String portion;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String tip;
  final String icon;

  const DietMealItem({
    required this.type,
    required this.time,
    required this.name,
    this.portion = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tip = '',
    this.icon = '🍽️',
  });
}

class DietDayPlan {
  final int dayNumber; // 1 to 7
  final String dayName; // 'Monday', 'Tuesday', ...
  final String dayShort; // 'Mon', 'Tue', ...
  final String dayFocus; // e.g. 'Omega-3 Neural Healing'
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final List<DietMealItem> meals;
  final String dailyTip;

  String get shortDay => dayShort;

  const DietDayPlan({
    required this.dayNumber,
    required this.dayName,
    required this.dayShort,
    required this.dayFocus,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.meals,
    this.dailyTip = '',
  });
}

class DietWeekOption {
  final String id;
  final String title;
  final String tag;
  final String description;
  final Color accentColor;
  final List<DietDayPlan> days;

  const DietWeekOption({
    required this.id,
    required this.title,
    required this.tag,
    required this.description,
    required this.accentColor,
    required this.days,
  });
}


import 'package:cloud_firestore/cloud_firestore.dart';

import 'BMI.dart';
import 'CustomFood.dart';
import 'Food.dart';
import 'Water.dart';

class CustomUser {
  String id;
  String name;
  int age;
  String email;
  double weight;
  double height;
  String role;
  List<Food>? foodLog;
  Water? waterLog;
  late BMI bmi;
  double totalCalories;
  double totalWaterIntake;
  String? profileImageUrl;
  int targetCalories;

  List<ConsumedFood>? consumedFoodLog = [];

  CustomUser({
    required this.id,
    required this.role,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    Water? waterLog,
    required this.email,
    this.profileImageUrl,
    this.totalCalories = 0,
    this.totalWaterIntake = 0,
    this.targetCalories = 2000,
  }) : waterLog = waterLog ?? Water() {
    bmi = BMI(weight: weight, height: height);
  }

  // ========================= 🔹 BMI =========================
  double calculateBMI() => bmi.calculateBMI();
  String getBMICategory() => bmi.getBMICategory();

  // ========================= 🔹 Log Food =========================
  void logFood(Food food) {
    foodLog!.add(food);
    totalCalories += food.calories;
  }

  void logConsumedFood(ConsumedFood consumedFood) {
    consumedFoodLog!.add(consumedFood);
  }

  // ========================= 🔹 Daily Summary (tất cả log, không theo ngày) =========================
  double getDailyCaloryIntake() {
    return consumedFoodLog!.fold(0, (total, food) => total + food.calories);
  }

  double getDailyCarbs() {
    return consumedFoodLog?.fold(0.0, (total, food) => total! + (food.carbs ?? 0.0)) ?? 0.0;
  }

  double getDailyFats() {
    return consumedFoodLog?.fold(0.0, (total, food) => total! + (food.fat ?? 0.0)) ?? 0.0;
  }

  double getDailyProtein() {
    return consumedFoodLog?.fold(0.0, (total, food) => total! + (food.protein ?? 0.0)) ?? 0.0;
  }

  // ========================= 🔹 Multi-day Diary Support =========================
  bool isSameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double getCaloriesByDate(DateTime date) {
    return consumedFoodLog!
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + food.calories);
  }

  double getCarbsByDate(DateTime date) {
    return consumedFoodLog!
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.carbs ?? 0.0));
  }

  double getFatsByDate(DateTime date) {
    return consumedFoodLog!
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.fat ?? 0.0));
  }

  double getProteinByDate(DateTime date) {
    return consumedFoodLog!
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.protein ?? 0.0));
  }

  List<ConsumedFood> getFoodsByDate(DateTime date) {
    return consumedFoodLog!
        .where((food) => isSameDate(food.timestamp, date))
        .toList();
  }

  // ========================= 🔹 Firestore mapping =========================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'foodLog': foodLog?.map((food) => food.toMap()).toList() ?? [],
      'waterLog': waterLog?.toMap() ?? {},
      'totalCalories': totalCalories,
      'totalWaterIntake': totalWaterIntake,
      'targetCalories': targetCalories,
      'profileImageUrl': profileImageUrl ?? '',
      'email': email,
      'role': role,
      'bmi': calculateBMI(),
    };
  }

  static Future<CustomUser> fromFirestore(Map<String, dynamic> data, String userId) async {
    final foodSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('foodLog')
        .get();

    final consumedFoodSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dailyFoodLog')
        .get();

    return CustomUser(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      age: data['age'] ?? 0,
      weight: (data['weight'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      waterLog: data['waterLog'] != null ? Water.fromMap(data['waterLog']) : Water(),
      targetCalories: data['targetCalories'] ?? 2000,
      profileImageUrl: data['profileImageUrl'],
      email: data['email'] ?? '',
      role: data['role'] ?? 'USER',
    )
      ..foodLog = foodSnapshot.docs.map((doc) => Food.fromMap(doc.data(), doc.id)).toList()
      ..consumedFoodLog = consumedFoodSnapshot.docs.map((doc) => ConsumedFood.fromMap(doc.data())).toList();
  }

  // ========================= 🔹 Save Consumed Food =========================
  Future<void> saveConsumedFood(ConsumedFood consumedFood) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Lưu vào log cũ
    final logRef = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('consumedFoodLog')
        .doc();
    batch.set(logRef, consumedFood.toMap());

    // 2. Lưu thêm vào lịch sử theo ngày
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('history')
        .doc(dateKey)
        .collection('consumedFoods')
        .doc();

    final historyData = consumedFood.toMap();
    historyData['timestamp'] = Timestamp.fromDate(consumedFood.timestamp);
    historyData['date'] = Timestamp.now();

    batch.set(historyRef, historyData);

    await batch.commit();
  }
}

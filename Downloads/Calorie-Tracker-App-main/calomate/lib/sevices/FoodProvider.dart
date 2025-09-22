import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modals/Food.dart';
import '../modals/CustomFood.dart';

class FoodProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userId;

  List<Food> _foodLog = [];
  List<ConsumedFood> _dailyFoodLog = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Food> get foodLog => _foodLog;
  List<ConsumedFood> get dailyFoodLog => _dailyFoodLog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FoodProvider({required this.userId}) {
    fetchFoodLog();
    fetchDailyFoodLog();
  }

  void updateUserId(String newUserId) {
    if (userId != newUserId) {
      userId = newUserId;
      fetchFoodLog();
      fetchDailyFoodLog();
    }
  }

  Future<void> fetchDailyFoodLog() async {
    _setLoading(true);
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final lastReset = (data?['lastReset'] as Timestamp?)?.toDate();
        final currentDate = DateTime.now();

        // Nếu muốn reset theo ngày, xử lý ở đây
        if (lastReset == null || currentDate.difference(lastReset).inHours >= 24) {
          // Reset logic nếu cần
        }
      }

      // Lấy log ăn uống
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyFoodLog')
          .orderBy('timestamp', descending: true)
          .get();

      _dailyFoodLog = snapshot.docs
          .map((doc) => ConsumedFood.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _setError(null);
    } catch (e) {
      _setError("Failed to fetch daily food log.");
      print("Error fetching daily food log: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logConsumedFood(ConsumedFood food) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyFoodLog')
          .doc();

      await docRef.set(food.toMap());
      _dailyFoodLog.insert(0, food);
      notifyListeners();
    } catch (e) {
      _setError("Failed to log consumed food.");
      print("Error logging consumed food: $e");
    }
  }

  // ===================== 🔹 OLD =====================
  int getMealCalories(String mealType) {
    return _dailyFoodLog
        .where((food) => food.mealType == mealType)
        .fold(0, (sum, food) => sum + food.calories);
  }

  // ===================== 🔹 NEW: Support by Date =====================
  bool isSameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int getMealCaloriesByDate(String mealType, DateTime date) {
    return _dailyFoodLog
        .where((food) => food.mealType == mealType && isSameDate(food.timestamp, date))
        .fold(0, (sum, food) => sum + food.calories);
  }

  List<ConsumedFood> getFoodsByDate(DateTime date) {
    return _dailyFoodLog.where((food) => isSameDate(food.timestamp, date)).toList();
  }

  int getCaloriesByDate(DateTime date) {
    return _dailyFoodLog
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0, (sum, food) => sum + food.calories);
  }

  double getCarbsByDate(DateTime date) {
    return _dailyFoodLog
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.carbs ?? 0.0));
  }

  double getFatsByDate(DateTime date) {
    return _dailyFoodLog
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.fat ?? 0.0));
  }

  double getProteinByDate(DateTime date) {
    return _dailyFoodLog
        .where((food) => isSameDate(food.timestamp, date))
        .fold(0.0, (sum, food) => sum + (food.protein ?? 0.0));
  }

  // ==================================================

  Future<void> fetchFoodLog() async {
    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodLog')
          .get();

      _foodLog = snapshot.docs
          .map((doc) => Food.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      _setError(null);
    } catch (e) {
      _setError("Failed to load food log.");
      print("Error fetching food log: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logFood(Food food) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('foodLog')
          .doc();

      await docRef.set(food.toMap());
      _foodLog.add(food);
      notifyListeners();
    } catch (e) {
      _setError("Failed to log food.");
      print("Error logging food: $e");
    }
  }

  Future<void> deleteFood(Food food) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodLog')
          .where('foodName', isEqualTo: food.foodName)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      _foodLog.removeWhere((item) => item.foodName == food.foodName);
      notifyListeners();
    } catch (e) {
      _setError("Failed to delete food.");
      print("Error deleting food: $e");
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}

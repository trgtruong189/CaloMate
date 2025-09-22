import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumedFood {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double foodWeight;
  final String mealType; // Breakfast, Lunch, Dinner, Snacks
  final DateTime timestamp; // Track when the food was consumed

  ConsumedFood({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.foodWeight,
    required this.mealType,
    required this.timestamp,
    required this.carbs,
  });

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'foodWeight': foodWeight,
      'mealType': mealType,
      'timestamp': Timestamp.fromDate(timestamp),
      'carbs': carbs,
    };
  }

  /// Create object from Firestore map
  factory ConsumedFood.fromMap(Map<String, dynamic> map) {
    // return ConsumedFood(
    //   foodName: map['foodName'] ?? '',
    //   calories: (map['calories'] ?? 0).toInt(),
    //   protein: _toDouble(map['protein']),
    //   fat: _toDouble(map['fat']),
    //   carbs: _toDouble(map['carbs']),
    //   foodWeight: _toDouble(map['foodWeight']),
    //   mealType: map['mealType'] ?? '',
    //   timestamp: _parseTimestamp(map['timestamp']),
    // );
    DateTime parsedTime;
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['date'] is Timestamp) {
      parsedTime = (map['date'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return ConsumedFood(
      foodName: map['foodName'] ?? '',
      calories: (map['calories'] ?? 0).toInt(),
      protein: _toDouble(map['protein']),
      fat: _toDouble(map['fat']),
      carbs: _toDouble(map['carbs']),
      foodWeight: _toDouble(map['foodWeight']),
      mealType: map['mealType'] ?? '',
      timestamp: parsedTime,
    );
  }

  /// Safe conversion helpers
  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();   // ✅ Firestore Timestamp
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Create a copy with updated fields
  ConsumedFood copyWith({
    String? foodName,
    int? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? foodWeight,
    String? mealType,
    DateTime? timestamp,
  }) {
    return ConsumedFood(
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      foodWeight: foodWeight ?? this.foodWeight,
      mealType: mealType ?? this.mealType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ConsumedFood {
//   final String foodName;
//   final int calories;
//   final double protein;
//   final double carbs;
//   final double fat;
//   final double foodWeight;
//   final String mealType; // Breakfast, Lunch, Dinner, Snacks
//   final DateTime timestamp; // Track when the food was consumed
//
//   ConsumedFood({
//     required this.foodName,
//     required this.calories,
//     required this.protein,
//     required this.fat,
//     required this.foodWeight,
//     required this.mealType,
//     required this.timestamp,
//     required this.carbs
//   });
//
//   /// Convert to map for Firestore
//   Map<String, dynamic> toMap() {
//     return {
//       'foodName': foodName,
//       'calories': calories,
//       'protein': protein,
//       'fat': fat,
//       'foodWeight': foodWeight,
//       'mealType': mealType,
//       // 'timestamp': timestamp.toIso8601String(),
//       'timestamp': Timestamp.fromDate(timestamp),
//       'carbs': carbs,
//     };
//   }
//
//   /// Create object from Firestore map
//   factory ConsumedFood.fromMap(Map<String, dynamic> map) {
//     return ConsumedFood(
//       // foodName: map['foodName'] ?? 'Unknown Food',
//       // calories: map['calories'] ?? 0,
//       // protein: (map['protein'] ?? 0).toDouble(),
//       // fat: (map['fat'] ?? 0).toDouble(),
//       // foodWeight: (map['foodWeight'] ?? 0).toDouble(),
//       // mealType: map['mealType'] ?? 'Unknown Meal',
//       // // timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
//       //   timestamp: _parseTimestamp(map['timestamp']),
//       // // carbs: map['carbs']
//       // carbs: _toDouble(map['carbs'])
//       foodName: map['foodName'] ?? '',
//       calories: (map['calories'] ?? 0).toInt(),
//       protein: (map['protein'] ?? 0).toDouble(),
//       fat: (map['fat'] ?? 0).toDouble(),
//       carbs: (map['carbs'] ?? 0).toDouble(),
//       foodWeight: (map['foodWeight'] ?? 0).toDouble(),
//       mealType: map['mealType'] ?? '',
//       timestamp: (map['timestamp'] is Timestamp)
//           ? (map['timestamp'] as Timestamp).toDate()
//           : DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
//     );
//   }
//   static double _toDouble(dynamic v, [double fallback = 0.0]) {
//     if (v == null) return fallback;
//     if (v is double) return v;
//     if (v is int) return v.toDouble();
//     if (v is String) return double.tryParse(v) ?? fallback;
//     return fallback;
//   }
//   static DateTime _parseTimestamp(dynamic value) {
//     if (value == null) return DateTime.now();
//     if (value is Timestamp) return value.toDate();   // ✅ Firestore Timestamp
//     if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
//     if (value is DateTime) return value;
//     return DateTime.now();
//   }
//
//
//
//
//
//
//   /// Create a copy with updated fields
//   ConsumedFood copyWith({
//     String? foodName,
//     int? calories,
//     double? protein,
//     double? fat,
//     double? carbs,
//     double? foodWeight,
//     String? mealType,
//     DateTime? timestamp,
//   }) {
//     return ConsumedFood(
//       foodName: foodName ?? this.foodName,
//       calories: calories ?? this.calories,
//       protein: protein ?? this.protein,
//       fat: fat ?? this.fat,
//       foodWeight: foodWeight ?? this.foodWeight,
//       mealType: mealType ?? this.mealType,
//       timestamp: timestamp ?? this.timestamp,
//       carbs: carbs ?? this.carbs
//     );
//   }
// }

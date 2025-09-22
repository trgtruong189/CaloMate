// AddFoodDialog.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../modals/CustomFood.dart';
import '../modals/Food.dart';
import '../sevices/FoodProvider.dart';
import '../sevices/UserProvider.dart';
import '../sevices/ThameProvider.dart';

class AddFoodDialog extends StatefulWidget {
  final String mealType;
  final DateTime? selectedDate; // optional, for backward compatibility

  AddFoodDialog({required this.mealType, this.selectedDate});

  @override
  _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final TextEditingController _quantityController = TextEditingController();
  Food? selectedFood;
  bool isLoading = true; // loading suggested foods
  bool isAdding = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserFoodList();
  }

  Future<void> _loadUserFoodList() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData(); // ensure foodLog loaded
      if (userProvider.foodLog.isEmpty) {
        setState(() {
          errorMessage = "Không tìm thấy món ăn nào trong nhật ký của bạn.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Không thể tải dữ liệu món ăn. Vui lòng thử lại.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime _composeTimestampForSelectedDate(DateTime baseDate) {
    // Use current time but with the selected date (so the day is the one user chose)
    final now = DateTime.now();
    return DateTime(baseDate.year, baseDate.month, baseDate.day, now.hour, now.minute, now.second);
  }

  Future<void> _addFood() async {
    if (selectedFood == null) {
      setState(() => errorMessage = "Vui lòng chọn 1 món ăn từ danh sách.");
      return;
    }

    if (_quantityController.text.isEmpty || double.tryParse(_quantityController.text) == null) {
      setState(() => errorMessage = "Vui lòng nhập số lượng hợp lệ.");
      return;
    }

    setState(() {
      isAdding = true;
      errorMessage = null;
    });

    try {
      final quantity = double.parse(_quantityController.text);
      final cal = (selectedFood!.calories * (quantity / selectedFood!.foodWeight)).round();

      final chosenDate = widget.selectedDate ?? DateTime.now();
      final timestamp = _composeTimestampForSelectedDate(chosenDate);

      final consumedFood = ConsumedFood(
        foodName: selectedFood!.foodName,
        calories: cal,
        protein: selectedFood!.protein,
        fat: selectedFood!.fat,
        foodWeight: quantity,
        mealType: widget.mealType,
        timestamp: timestamp,
        carbs: selectedFood!.carbs,
      );

      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      if (currentUser == null) throw "Không có người dùng";

      // 1) save into user's dailyFoodLog via provider (keeps existing behaviour)
      await foodProvider.logConsumedFood(consumedFood);

      // 2) add to in-memory user object (so summaries use it immediately)
      currentUser.logConsumedFood(consumedFood);

      // 3) write to history/{dateKey}/consumedFoods with correct dateKey derived from timestamp
      final dateKey = "${timestamp.year}-${timestamp.month.toString().padLeft(2,'0')}-${timestamp.day.toString().padLeft(2,'0')}";
      final historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .collection('history')
          .doc(dateKey)
          .collection('consumedFoods')
          .doc();
      final historyData = consumedFood.toMap();
      historyData['timestamp'] = Timestamp.fromDate(consumedFood.timestamp);
      historyData['dateKey'] = dateKey;
      await historyRef.set(historyData);

      // 4) refresh provider/user data so UI updates
      await foodProvider.fetchDailyFoodLog();
      await userProvider.loadUserData();

      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = "Thêm món ăn không thành công: $e");
    } finally {
      setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final userProvider = Provider.of<UserProvider>(context);
    final foodSuggestions = userProvider.foodLog;

    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm món ăn - ${widget.mealType}"),
        backgroundColor: isDarkMode ? Colors.black : Colors.green[700],
      ),
      body: isLoading
          ? Center(child: SpinKitFadingCircle(color: Colors.green, size: 40))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<Food>(
              decoration: InputDecoration(labelText: "Chọn món (gợi ý)"),
              items: foodSuggestions.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f.foodName),
                );
              }).toList(),
              onChanged: (f) => setState(() => selectedFood = f),
              value: selectedFood,
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Số lượng (grams)",
              ),
            ),
            const SizedBox(height: 12),
            if (errorMessage != null) Text(errorMessage!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            isAdding
                ? SpinKitCircle(color: Colors.green)
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: _addFood,
                    child: Text("Thêm"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.greenAccent : Colors.green[700],
                    )),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Huỷ"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}

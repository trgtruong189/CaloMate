// DiaryScreen.dart
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modals/CustomFood.dart';
import '../modals/Users.dart';
import '../sevices/FoodProvider.dart';
import '../sevices/ThameProvider.dart';
import '../sevices/UserProvider.dart';
import '../sevices/WaterProvider.dart';
import 'AddFoodDialog.dart';
import 'DiaryCalendar.dart';

class DiaryScreen extends StatefulWidget {
  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late TextEditingController caloryController;
  late TextEditingController waterController;
  late TextEditingController updateWaterController;

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    caloryController = TextEditingController();
    waterController = TextEditingController();
    updateWaterController = TextEditingController();
    loadUserData();
    // ensure providers load daily log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fp = Provider.of<FoodProvider>(context, listen: false);
      fp.fetchDailyFoodLog();
    });
  }

  Future<void> loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      // your project already has loadUserData() used previously
      await userProvider.loadUserData();
      if (mounted) {
        final user = userProvider.user;
        if (user != null) {
          setState(() {
            caloryController.text = user.targetCalories.toString();
            waterController.text =
                user.waterLog?.targetWaterConsumption.toInt().toString() ??
                    (user.weight * 35).toInt().toString();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải thông tin: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    caloryController.dispose();
    waterController.dispose();
    updateWaterController.dispose();
    super.dispose();
  }

  // Helper: dateKey yyyy-MM-dd
  String dateKeyFrom(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // Show edit dialog for a consumed food
  void _showEditFoodDialog(BuildContext context, ConsumedFood food) {
    final nameCtrl = TextEditingController(text: food.foodName);
    final calCtrl = TextEditingController(text: food.calories.toString());
    final proteinCtrl = TextEditingController(text: food.protein.toString());
    final carbCtrl = TextEditingController(text: food.carbs.toString());
    final fatCtrl = TextEditingController(text: food.fat.toString());
    final mealTypeCtrl = ValueNotifier<String>(food.mealType);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Chỉnh sửa món ăn"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Tên món")),
                TextField(controller: calCtrl, decoration: InputDecoration(labelText: "Calories"), keyboardType: TextInputType.number),
                TextField(controller: proteinCtrl, decoration: InputDecoration(labelText: "Protein (g)"), keyboardType: TextInputType.number),
                TextField(controller: carbCtrl, decoration: InputDecoration(labelText: "Carbs (g)"), keyboardType: TextInputType.number),
                TextField(controller: fatCtrl, decoration: InputDecoration(labelText: "Fat (g)"), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                ValueListenableBuilder<String>(
                  valueListenable: mealTypeCtrl,
                  builder: (_, value, __) {
                    return DropdownButton<String>(
                      value: value,
                      items: ["Bữa sáng", "Bữa trưa", "Bữa tối", "Ăn vặt"]
                          .map((e) => DropdownMenuItem(child: Text(e), value: e))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) mealTypeCtrl.value = v;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Huỷ")),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // close first
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final foodProvider = Provider.of<FoodProvider>(context, listen: false);
                final currentUser = userProvider.user;
                if (currentUser == null) return;

                // build updated food
                final updated = food.copyWith(
                  foodName: nameCtrl.text,
                  calories: int.tryParse(calCtrl.text) ?? food.calories,
                  protein: double.tryParse(proteinCtrl.text) ?? food.protein,
                  carbs: double.tryParse(carbCtrl.text) ?? food.carbs,
                  fat: double.tryParse(fatCtrl.text) ?? food.fat,
                  mealType: mealTypeCtrl.value,
                );

                // Update in Firestore:
                try {
                  final userId = currentUser.id;
                  // 1) update dailyFoodLog documents that match by timestamp + foodName + mealType
                  final ts = Timestamp.fromDate(food.timestamp);
                  final dailyQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('dailyFoodLog')
                      .where('timestamp', isEqualTo: ts)
                      .where('foodName', isEqualTo: food.foodName)
                      .where('mealType', isEqualTo: food.mealType)
                      .get();

                  for (var doc in dailyQuery.docs) {
                    await doc.reference.update(updated.toMap());
                  }

                  // 2) update history doc(s)
                  final dateKey = dateKeyFrom(food.timestamp);
                  final histQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('history')
                      .doc(dateKey)
                      .collection('consumedFoods')
                      .where('timestamp', isEqualTo: ts)
                      .where('foodName', isEqualTo: food.foodName)
                      .where('mealType', isEqualTo: food.mealType)
                      .get();

                  for (var doc in histQuery.docs) {
                    await doc.reference.update(updated.toMap());
                  }

                  // Refresh providers
                  await foodProvider.fetchDailyFoodLog();
                  await userProvider.loadUserData();

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cập nhật thành công")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cập nhật thất bại: $e")));
                }
              },
              child: Text("Lưu"),
            ),
            TextButton(
              onPressed: () async {
                // Delete operation
                Navigator.pop(ctx);
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final foodProvider = Provider.of<FoodProvider>(context, listen: false);
                final currentUser = userProvider.user;
                if (currentUser == null) return;
                final userId = currentUser.id;

                try {
                  final ts = Timestamp.fromDate(food.timestamp);
                  final dailyQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('dailyFoodLog')
                      .where('timestamp', isEqualTo: ts)
                      .where('foodName', isEqualTo: food.foodName)
                      .where('mealType', isEqualTo: food.mealType)
                      .get();
                  for (var doc in dailyQuery.docs) await doc.reference.delete();

                  final dateKey = dateKeyFrom(food.timestamp);
                  final histQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('history')
                      .doc(dateKey)
                      .collection('consumedFoods')
                      .where('timestamp', isEqualTo: ts)
                      .where('foodName', isEqualTo: food.foodName)
                      .where('mealType', isEqualTo: food.mealType)
                      .get();
                  for (var doc in histQuery.docs) await doc.reference.delete();

                  await foodProvider.fetchDailyFoodLog();
                  await userProvider.loadUserData();

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xóa thành công")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xóa thất bại: $e")));
                }
              },
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget buildSummarySection(BuildContext context, bool isDarkMode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return FutureBuilder<CustomUser?>(
      future: userProvider.findCurrentCustomUser?.call() ?? Future.value(userProvider.user),
      builder: (context, snapshot) {
        final customUser = snapshot.data ?? userProvider.user;
        if (customUser == null) {
          return SizedBox.shrink();
        }
        final remainingCalories = (customUser.targetCalories) - customUser.getCaloriesByDate(_selectedDate);
        final carbs = customUser.getCarbsByDate(_selectedDate);
        final fats = customUser.getFatsByDate(_selectedDate);
        final protein = customUser.getProteinByDate(_selectedDate);
        final calorieProgressValue =
        (customUser.getCaloriesByDate(_selectedDate) / (customUser.targetCalories == 0 ? 1 : customUser.targetCalories))
            .clamp(0.0, 1.0);

        return _buildAnimatedCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Calories
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 140,
                              width: 140,
                              child: CircularProgressIndicator(
                                value: calorieProgressValue,
                                backgroundColor:
                                isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode ? Colors.greenAccent : Colors.green,
                                ),
                                strokeWidth: 12,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${remainingCalories > 0 ? remainingCalories : 0}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.greenAccent
                                        : Colors.green[800],
                                  ),
                                ),
                                const Text("Remaining"),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Calories",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.greenAccent
                                : Colors.green[700],
                          ),
                        ),
                        Text(
                          "${customUser.getCaloriesByDate(_selectedDate)} / ${customUser.targetCalories}",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  // Macros
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _macroNutrientRow("Carbs", carbs, isDarkMode, Icons.rice_bowl),
                        const SizedBox(height: 10),
                        _macroNutrientRow("Fats", fats, isDarkMode, Icons.water_drop),
                        const SizedBox(height: 10),
                        _macroNutrientRow("Protein", protein, isDarkMode, Icons.egg),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _macroNutrientRow(String label, double value, bool isDarkMode, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Icon(icon), const SizedBox(width: 5), Text(label)]),
        Text("${value.toInt()} g"),
      ],
    );
  }

  Widget buildMealSection(BuildContext context, String mealType, bool isDarkMode) {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final foodsForDate = foodProvider.getFoodsByDate(_selectedDate)
            .where((food) => food.mealType == mealType)
            .toList();

        final mealCalories = foodsForDate.fold(0, (sum, f) => sum + f.calories);

        return _buildCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddFoodDialog(
                        mealType: mealType,
                        selectedDate: _selectedDate,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.fastfood, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mealType,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.greenAccent
                                      : Colors.green[800])),
                          Text("Calories: $mealCalories Cal"),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFoodDialog(
                              mealType: mealType,
                              selectedDate: _selectedDate,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // List each food for this meal and date
              ...foodsForDate.map((food) => ListTile(
                title: Text(food.foodName),
                subtitle: Text("${food.calories} Cal • P:${food.protein}g C:${food.carbs}g F:${food.fat}g"),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditFoodDialog(context, food),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget buildWaterSection(BuildContext context, bool isDarkMode) {
    return Consumer<WaterProvider>(
      builder: (context, waterProvider, child) {
        final targetWater = waterProvider.waterLog.targetWaterConsumption;
        final waterIntake = waterProvider.waterLog.currentWaterConsumption;
        final remainingWater = (targetWater - waterIntake).clamp(0.0, targetWater);

        return _buildAnimatedCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Lượng nước tiêu thụ', isDarkMode),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (waterIntake / (targetWater == 0 ? 1 : targetWater)).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: updateWaterController,
                      decoration: const InputDecoration(
                        labelText: "Thêm lượng nước (ml)",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final addedWater =
                          double.tryParse(updateWaterController.text) ?? 0.0;
                      if (addedWater > 0) {
                        waterProvider.logWater(addedWater);
                        updateWaterController.clear();
                      }
                    },
                    child: const Text("Thêm"),
                  )
                ],
              ),
              Text("Tiêu thụ: ${waterIntake.toInt()} ml"),
              Text("Còn lại: ${remainingWater.toInt()} ml"),
            ],
          ),
        );
      },
    );
  }

  Widget buildTargetSection(BuildContext context, bool isDarkMode) {
    return _buildCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Đặt mục tiêu hằng ngày', isDarkMode),
          const SizedBox(height: 10),

          const SizedBox(height: 10),
          TextField(
            controller: waterController,
            decoration: const InputDecoration(labelText: "Nước mục tiêu (ml)"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final userProvider =
              Provider.of<UserProvider>(context, listen: false);
              final waterProvider =
              Provider.of<WaterProvider>(context, listen: false);

              final newCalories = int.tryParse(caloryController.text) ?? 2000;
              final newWater = double.tryParse(waterController.text) ?? 2000;

              userProvider.setTargetCalories(newCalories);
              waterProvider.setTargetWaterConsumption(newWater);
            },
            child: const Text("Cập nhật"),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDarkMode) {
    return Text(title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.greenAccent : Colors.green[800]));
  }

  Widget _buildCard({required Widget child, required bool isDarkMode}) {
    return Card(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(padding: const EdgeInsets.all(12.0), child: child),
    );
  }

  Widget _buildAnimatedCard({required Widget child, required bool isDarkMode}) {
    return SlideInUp(
      duration: const Duration(milliseconds: 500),
      child: _buildCard(child: child, isDarkMode: isDarkMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xffe6ffe6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(45),
        child: SafeArea(
          child: Center(
            child: Text(
              "Nhật ký",
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.greenAccent : Colors.green,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DiaryCalendar(
                displayedMonth: _displayedMonth,
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                onMonthChanged: (month) {
                  setState(() {
                    _displayedMonth = month;
                  });
                },
              ),
              const SizedBox(height: 10),
              buildSummarySection(context, isDarkMode),
              const SizedBox(height: 20),
              buildMealSection(context, "Bữa sáng", isDarkMode),
              buildMealSection(context, "Bữa trưa", isDarkMode),
              buildMealSection(context, "Bữa tối", isDarkMode),
              buildMealSection(context, "Ăn vặt", isDarkMode),
              const SizedBox(height: 20),
              buildWaterSection(context, isDarkMode),
              const SizedBox(height: 20),
              buildTargetSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }
}

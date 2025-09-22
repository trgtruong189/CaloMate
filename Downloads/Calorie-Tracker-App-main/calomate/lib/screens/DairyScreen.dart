import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  }

  Future<void> loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Calendar
              DiaryCalendar(
                displayedMonth: _displayedMonth,
                selectedDate: _selectedDate, // ✅ thêm tham số
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

  // ================= SUMMARY =================
  Widget buildSummarySection(BuildContext context, bool isDarkMode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return FutureBuilder<CustomUser?>(
      future: userProvider.findCurrentCustomUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          final customUser = snapshot.data!;
          final remainingCalories =
              (customUser.targetCalories) - customUser.getCaloriesByDate(_selectedDate);
          final carbs = customUser.getCarbsByDate(_selectedDate);
          final fats = customUser.getFatsByDate(_selectedDate);
          final protein = customUser.getProteinByDate(_selectedDate);
          final calorieProgressValue =
          (customUser.getCaloriesByDate(_selectedDate) / customUser.targetCalories)
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
                          _macroNutrientRow("Carbs", carbs, isDarkMode,
                              Colors.orangeAccent, Icons.rice_bowl),
                          const SizedBox(height: 10),
                          _macroNutrientRow("Fats", fats, isDarkMode,
                              Colors.blueAccent, Icons.water_drop),
                          const SizedBox(height: 10),
                          _macroNutrientRow("Protein", protein, isDarkMode,
                              Colors.purpleAccent, Icons.egg),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text("Không có dữ liệu người dùng."));
        }
      },
    );
  }

  // ================= MEALS =================
  Widget buildMealSection(BuildContext context, String mealType, bool isDarkMode) {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final mealCalories =
        foodProvider.getMealCaloriesByDate(mealType, _selectedDate);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddFoodDialog(mealType: mealType),
              ),
            );
          },
          child: _buildCard(
            isDarkMode: isDarkMode,
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
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= WATER =================
  Widget buildWaterSection(BuildContext context, bool isDarkMode) {
    return Consumer<WaterProvider>(
      builder: (context, waterProvider, child) {
        final targetWater = waterProvider.waterLog.targetWaterConsumption;
        final waterIntake = waterProvider.waterLog.currentWaterConsumption; // ✅ fix lỗi
        final remainingWater = (targetWater - waterIntake).clamp(0.0, targetWater);

        return _buildAnimatedCard(
          isDarkMode: isDarkMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Lượng nước tiêu thụ', isDarkMode),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (waterIntake / targetWater).clamp(0.0, 1.0),
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
                        waterProvider.logWater(addedWater); // ✅ fix lỗi
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

  // ================= TARGET =================
  Widget buildTargetSection(BuildContext context, bool isDarkMode) {
    return _buildCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Đặt mục tiêu hằng ngày', isDarkMode),
          const SizedBox(height: 10),
          TextField(
            controller: caloryController,
            decoration: const InputDecoration(labelText: "Calories mục tiêu"),
            keyboardType: TextInputType.number,
          ),
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

  // ================= UI HELPERS =================
  Widget _macroNutrientRow(
      String label, double value, bool isDarkMode, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Icon(icon, color: color), const SizedBox(width: 5), Text(label)]),
        Text("${value.toInt()} g"),
      ],
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
}

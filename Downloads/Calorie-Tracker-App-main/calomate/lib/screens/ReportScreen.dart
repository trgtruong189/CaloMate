// ReportsScreen.dart
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sevices/FoodProvider.dart';
import '../sevices/ThameProvider.dart'; // giữ nguyên theo file bạn đang dùng
import '../sevices/UserProvider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final Color primaryColor = isDarkMode ? Colors.greenAccent : const Color(0xFF4CAF50);
    final Color secondaryColor = isDarkMode ? Colors.green : const Color(0xFF81C784);
    final Color backgroundColor = isDarkMode ? Colors.black : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        title: const Text(
          "Báo cáo dinh dưỡng",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer2<FoodProvider, UserProvider>(
          builder: (context, foodProvider, userProvider, child) {
            if (foodProvider.isLoading || userProvider.user == null) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }
            if (foodProvider.dailyFoodLog.isEmpty) {
              return Center(
                child: Text(
                  "No data available for this month.",
                  style: TextStyle(
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              );
            }

            return ListView(
              children: [
                _buildAnimatedSectionHeader("Báo cáo", primaryColor),
                _buildAnimatedSummaryCard(foodProvider, primaryColor),
                const SizedBox(height: 20),
                _buildAnimatedSectionHeader("Phân tích thành phần dinh dưỡng", primaryColor),
                _buildAnimatedNutrientBreakdownChart(foodProvider, primaryColor),
                const SizedBox(height: 20),
                _buildAnimatedSectionHeader("Biểu đồ xu hướng calo", primaryColor),
                _buildAnimatedCaloriesTrendChart(foodProvider, primaryColor),
                const SizedBox(height: 20),
                _buildAnimatedSectionHeader("Tiến trình bổ sung nước", primaryColor),
                _buildAnimatedHydrationProgress(userProvider, primaryColor, secondaryColor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedSectionHeader(String title, Color color) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSummaryCard(FoodProvider foodProvider, Color primaryColor) {
    final totalCalories = foodProvider.dailyFoodLog.fold<int>(
        0, (sum, food) => sum + ((food.calories ?? 0) is int ? (food.calories as int) : (food.calories ?? 0).toInt()));
    final avgDailyCalories = (totalCalories / max(1, foodProvider.dailyFoodLog.length)).toInt();

    // an toàn khi danh sách không rỗng
    final caloriesList = foodProvider.dailyFoodLog.map((e) => (e.calories ?? 0).toDouble()).toList();
    final highestCalories = caloriesList.isNotEmpty ? caloriesList.reduce(max).toInt() : 0;
    final lowestCalories = caloriesList.isNotEmpty ? caloriesList.reduce(min).toInt() : 0;

    return SlideInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryTile("Total", "$totalCalories Cal", primaryColor),
                  _buildSummaryTile("Avg Daily", "$avgDailyCalories Cal", Colors.teal),
                  _buildSummaryTile("Highest", "$highestCalories Cal", Colors.redAccent),
                  _buildSummaryTile("Lowest", "$lowestCalories Cal", Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // === Helper: lấy DateTime an toàn từ một log item ===
  DateTime _extractDate(dynamic log) {
    try {
      // thử các trường phổ biến: date, createdAt, timestamp
      final dynamic v = (log as dynamic).date ??
          (log as dynamic).createdAt ??
          (log as dynamic).timestamp ??
          (log as dynamic).time;

      if (v == null) return DateTime.now();

      if (v is DateTime) return v;
      if (v is int) {
        // có thể là seconds hoặc milliseconds, cố gắng đoán:
        if (v > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(v);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000);
        }
      }
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        return parsed ?? DateTime.now();
      }
    } catch (_) {
      // bỏ qua lỗi
    }
    return DateTime.now();
  }

  /// === Biểu đồ xu hướng calo đã sửa lỗi và an toàn hơn ===
  Widget _buildAnimatedCaloriesTrendChart(FoodProvider foodProvider, Color primaryColor) {
    final logs = foodProvider.dailyFoodLog;
    // tạo danh sách spots an toàn
    final List<FlSpot> spots = [];
    for (var i = 0; i < logs.length; i++) {
      final cal = (logs[i].calories ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), cal));
    }

    // tính min/max cho trục Y có lề
    final double maxY = spots.isNotEmpty ? spots.map((s) => s.y).reduce(max) : 1000.0;
    final double minY = spots.isNotEmpty ? spots.map((s) => s.y).reduce(min) : 0.0;
    final double range = (maxY - minY).abs();
    final double topPadding = max(50.0, range * 0.15);
    final double bottomPadding = max(0.0, range * 0.05);
    final double chartMaxY = (maxY + topPadding);
    final double chartMinY = max(0.0, minY - bottomPadding);

    // interval cho trục Y (chia làm 4 đoạn nếu có thể)
    double yInterval = (range / 4).abs();
    if (yInterval <= 0) yInterval = max(100.0, (maxY / 4).abs());
    yInterval = yInterval.ceilToDouble();

    // interval cho trục X: hiển thị tối đa ~6 nhãn
    final double xInterval = (logs.length > 6) ? (logs.length / 6).floorToDouble() : 1.0;

    return ZoomIn(
      duration: const Duration(milliseconds: 1000),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: yInterval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // format: 1000 Cal
                        final intVal = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            "$intVal Cal",
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: xInterval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int idx = value.toInt();
                        if (idx < 0 || idx >= logs.length) return const SizedBox.shrink();

                        final date = _extractDate(logs[idx]);
                        final label = "${date.day}/${date.month}";
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot spot) => Colors.black87,
                    tooltipRoundedRadius: 8, // thay cho tooltipBorderRadius
                    tooltipMargin: 8,        // khoảng cách tooltip với điểm
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final date = (idx >= 0 && idx < logs.length) ? _extractDate(logs[idx]) : DateTime.now();
                        return LineTooltipItem(
                          "${date.day}/${date.month}\n${spot.y.toInt()} Cal",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),


                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.6), primaryColor],
                    ),
                    barWidth: 3.5,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.22),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNutrientBreakdownChart(FoodProvider foodProvider, Color primaryColor) {
    final carbs = foodProvider.dailyFoodLog.fold<double>(
        0.0, (sum, food) => sum + ((food.carbs ?? 0) is double ? (food.carbs as double) : (food.carbs ?? 0).toDouble()));
    final protein = foodProvider.dailyFoodLog.fold<double>(
        0.0, (sum, food) => sum + ((food.protein ?? 0) is double ? (food.protein as double) : (food.protein ?? 0).toDouble()));
    final fats = foodProvider.dailyFoodLog.fold<double>(
        0.0, (sum, food) => sum + ((food.fat ?? 0) is double ? (food.fat as double) : (food.fat ?? 0).toDouble()));

    final total = carbs + protein + fats;
    // tránh chia cho 0
    final List<PieChartSectionData> sections = [];
    if (total > 0) {
      sections.add(PieChartSectionData(
          value: carbs, color: Colors.lightGreen, title: "Carbs\n${((carbs / total) * 100).toStringAsFixed(0)}%"));
      sections.add(PieChartSectionData(
          value: protein, color: Colors.teal, title: "Protein\n${((protein / total) * 100).toStringAsFixed(0)}%"));
      sections.add(PieChartSectionData(
          value: fats, color: Colors.yellowAccent, title: "Fats\n${((fats / total) * 100).toStringAsFixed(0)}%"));
    } else {
      sections.add(PieChartSectionData(value: 1, color: Colors.grey, title: "No data"));
    }

    return FadeInRight(
      duration: const Duration(milliseconds: 800),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sections: sections,
                borderData: FlBorderData(show: false),
                centerSpaceRadius: 40,
                sectionsSpace: 6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHydrationProgress(UserProvider userProvider, Color primaryColor, Color secondaryColor) {
    final waterLog = userProvider.user?.waterLog;
    final currentWater = waterLog?.currentWaterConsumption ?? 0.0;
    final targetWater = waterLog?.targetWaterConsumption ?? 3000.0;

    final progress = (targetWater > 0) ? (currentWater / targetWater).clamp(0.0, 1.0) : 0.0;

    return SlideInLeft(
      duration: const Duration(milliseconds: 800),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                color: primaryColor,
                backgroundColor: secondaryColor.withOpacity(0.3),
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                "${currentWater.toInt()} ml / ${targetWater.toInt()} ml",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

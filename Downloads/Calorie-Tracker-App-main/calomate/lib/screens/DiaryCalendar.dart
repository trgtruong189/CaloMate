import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A calendar widget for selecting dates in the diary
class DiaryCalendar extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const DiaryCalendar({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });


  @override
  Widget build(BuildContext context) {
    final daysInMonth = getDaysInMonth();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final previousMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month - 1,
                      1,
                    );
                    onMonthChanged(previousMonth);
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(displayedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final nextMonth = DateTime(
                      displayedMonth.year,
                      displayedMonth.month + 1,
                      1,
                    );
                    onMonthChanged(nextMonth);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Calendar grid
          Container(
            height: 220, // Đặt chiều cao cố định cho lịch
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final day = daysInMonth[index];

                if (day == null) {
                  return const SizedBox.shrink();
                }

                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                final isCurrentMonth = day.month == displayedMonth.month;

                return GestureDetector(
                  onTap: () => onDateSelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.green : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth ? Colors.black : Colors.grey),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime?> getDaysInMonth() {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);

    // Xác định ngày đầu tiên để hiển thị (có thể từ tháng trước)
    // Trong Dart, weekday là 1-7 trong đó 1 là Thứ Hai và 7 là Chủ Nhật
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // Tạo danh sách để chứa tất cả các ngày cần hiển thị
    List<DateTime?> days = [];

    // Thêm các ngày từ tháng trước
    for (int i = 1; i < firstWeekdayOfMonth; i++) {
      days.add(null);
    }

    // Thêm tất cả các ngày của tháng hiện tại
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(displayedMonth.year, displayedMonth.month, i));
    }

    // Thêm các ngày từ tháng sau để hoàn thành lưới (7 cột)
    int remainingDays = (7 - (days.length % 7)) % 7;
    for (int i = 0; i < remainingDays; i++) {
      days.add(null);
    }

    return days;
  }
}
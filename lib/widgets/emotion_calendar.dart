import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'emotion_glass_day.dart';
import '../utils/emotion_utils.dart';

class EmotionCalendar extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime? selectedDayReference;
  final int? selectedDay;
  final Map<DateTime, Map<String, dynamic>> dayData;
  final Function(int) onDaySelected;
  final Function(DateTime) onMonthChanged;
  final bool isForward;
  final int previousMonth;

  const EmotionCalendar({
    required this.focusedDate,
    required this.selectedDayReference,
    required this.selectedDay,
    required this.dayData,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.isForward,
    required this.previousMonth,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final totalDaysInMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0).day;
    final firstWeekday = (firstDayOfMonth.weekday + 6) % 7;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= totalDaysInMonth; day++) {
      final isSelected = selectedDay != null &&
          selectedDayReference != null &&
          selectedDay == day &&
          focusedDate.month == selectedDayReference!.month &&
          focusedDate.year == selectedDayReference!.year;

      final hasTwoEmotions = getColor2ForDay(day, focusedDate, dayData) != null;
      final double scaleFactor = isSelected ? (hasTwoEmotions ? 0.6 : 0.75) : 1.0;

      dayWidgets.add(
        GestureDetector(
          onTap: () => onDaySelected(day),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: scaleFactor),
            duration: Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, animatedScale, child) {
              return EmotionGlassDay(
                key: ValueKey('${day}_$isSelected'),
                day: day,
                color1: getColor1ForDay(day, focusedDate, dayData),
                color2: getColor2ForDay(day, focusedDate, dayData),
                percentage: getPercentageForDay(day, focusedDate, dayData),
                scaleHeight: animatedScale,
                animate: isSelected,
              );
            },
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    final newDate = DateTime(focusedDate.year, focusedDate.month - 1);
                    onMonthChanged(newDate);
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(focusedDate).toUpperCase(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    final newDate = DateTime(focusedDate.year, focusedDate.month + 1);
                    onMonthChanged(newDate);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 7 / 5.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: dayWidgets,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

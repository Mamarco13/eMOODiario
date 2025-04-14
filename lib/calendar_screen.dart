// calendar_screen.dart
import 'package:flutter/material.dart';
import 'emotion_glass_day.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  int? _selectedDay;

  List<Color> emotionColors = [
    Colors.yellow,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.green,
    Colors.orange,
  ];

  final List<String> weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  Color getColor1ForDay(int day) {
    if (day % 7 == 0) return Colors.yellow;
    if (day % 5 == 0) return Colors.red;
    return emotionColors[(day - 1) % emotionColors.length];
  }

  Color? getColor2ForDay(int day) {
    if (day % 7 == 0) return Colors.blue;
    if (day % 5 == 0) return Colors.green;
    return null;
  }

  double getPercentageForDay(int day) {
    if (day % 7 == 0) return 0.6;
    if (day % 5 == 0) return 0.4;
    return 0.95;
  }

  Widget _buildEmotionPreview(int day) {
    final color1 = getColor1ForDay(day);
    final color2 = getColor2ForDay(day);
    final gradient = color2 != null
        ? LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color1.withOpacity(0.5), color2.withOpacity(0.5)],
          )
        : LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color1.withOpacity(0.5), color1.withOpacity(0.3)],
          );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/sample.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: gradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emoción del día',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Una frase opcional sobre cómo fue tu día.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final totalDaysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstWeekday = (firstDayOfMonth.weekday + 6) % 7;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

for (int day = 1; day <= totalDaysInMonth; day++) {
  final widget = GestureDetector(
    onTap: () {
      setState(() {
        _selectedDay = day;
      });
    },
    child: EmotionGlassDay(
      key: ValueKey('${day}_${_selectedDay == day}'),
      day: day,
      color1: getColor1ForDay(day),
      color2: getColor2ForDay(day),
      percentage: getPercentageForDay(day),
      animate: _selectedDay == day,
    ),
  );

  dayWidgets.add(widget);
}




    return Scaffold(
      backgroundColor: Color(0xFFF3F6FD),
      appBar: AppBar(
        title: Text('Mis Recuerdos', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (_selectedDay != null) _buildEmotionPreview(_selectedDay!),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month - 1,
                      );
                      _selectedDay = null;
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(_focusedDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month + 1,
                      );
                      _selectedDay = null;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: dayWidgets,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

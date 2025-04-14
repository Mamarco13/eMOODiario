import 'package:flutter/material.dart';
import 'emotion_glass_day.dart';
import 'edit_day_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:hive/hive.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  int? _selectedDay;

  Map<DateTime, Map<String, dynamic>> dayData = {};

  final List<String> weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('emotionsBox');
    final Map<DateTime, Map<String, dynamic>> loadedData = {};

    for (final key in box.keys) {
      final raw = box.get(key);
      final date = DateTime.parse(key);
      loadedData[date] = {
        'title': raw['title'],
        'phrase': raw['phrase'],
        'color1': Color(raw['color1']),
        'color2': raw['color2'] != null ? Color(raw['color2']) : null,
        'percentage': raw['percentage'],
        'media': (raw['media'] as List).map((p) => File(p)).toList(),
      };
    }

    setState(() {
      dayData = loadedData;
    });
  }

  Color getColor1ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    return dayData[date]?['color1'] ?? Colors.grey.shade300;
  }

  Color? getColor2ForDay(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    return dayData[date]?['color2'];
  }

  double getPercentageForDay(int day, {bool isSelected = false}) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final raw = dayData[date]?['percentage'] ?? 0.95;
    if (isSelected) {
      return 0.75;
    }
    return raw;
  }

  Widget _buildEmotionPreview(int day) {
    final date = DateTime(_focusedDate.year, _focusedDate.month, day);
    final data = dayData[date];
    final color1 = data?['color1'] ?? Colors.grey.shade300;
    final color2 = data?['color2'];
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

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditDayScreen(
              day: day,
              date: date,
              initialColor1: data?['color1'] ?? Colors.yellow,
              initialColor2: data?['color2'],
              initialPercentage: data?['percentage'] ?? 1.0,
            ),
            settings: RouteSettings(
              arguments: {
                'title': data?['title'],
                'phrase': data?['phrase'],
                'media': data?['media']?.map((f) => f.path).toList() ?? [],
              },
            ),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          final parsedData = {
            'title': result['title'],
            'phrase': result['phrase'],
            'color1': Color(result['color1']),
            'color2': result['color2'] != null ? Color(result['color2']) : null,
            'percentage': result['percentage'],
            'media': (result['media'] as List).map((p) => File(p)).toList(),
          };

          final storageData = {
            'title': result['title'],
            'phrase': result['phrase'],
            'color1': result['color1'],
            'color2': result['color2'],
            'percentage': result['percentage'],
            'media': result['media'],
          };

          Hive.box('emotionsBox').put(date.toString(), storageData);

          setState(() {
            dayData[date] = parsedData;
          });
        }
      },
      child: Padding(
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
              if (data?['media'] != null && data!['media'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    data['media'][0],
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
                      data?['title'] ?? 'Sin título',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      data?['phrase'] ?? 'Sin descripción',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      final isSelected = _selectedDay == day;
      final widget = GestureDetector(
        onTap: () {
          setState(() {
            _selectedDay = day;
          });
        },
        child: EmotionGlassDay(
          key: ValueKey('${day}_$isSelected'),
          day: day,
          color1: getColor1ForDay(day),
          color2: getColor2ForDay(day),
          percentage: isSelected && getColor2ForDay(day) != null ? 0.375 : getPercentageForDay(day, isSelected: isSelected),
          animate: isSelected,
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
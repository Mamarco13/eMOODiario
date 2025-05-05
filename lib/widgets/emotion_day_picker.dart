
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<List<DateTime>?> showEmotionDayPicker(
  BuildContext context,
  Map<DateTime, Map<String, dynamic>> dayData,
) async {
  final now = DateTime.now();
  DateTime focusedMonth = DateTime(now.year, now.month);
  final Set<DateTime> selected = {};

  return await showDialog<List<DateTime>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Selecciona días con emoción'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final totalDays = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
            final firstWeekday = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
            final List<Widget> dayWidgets = [];

            // Espacios vacíos antes del primer día
            for (int i = 0; i < firstWeekday; i++) {
              dayWidgets.add(Container());
            }

            for (int day = 1; day <= totalDays; day++) {
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final media = dayData[date]?['media'] ?? [];
              final color = media.isNotEmpty ? media[0].color1 : Colors.grey.shade300;
              final isSelected = selected.contains(date);

              dayWidgets.add(
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) selected.remove(date);
                      else selected.add(date);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 400,
              width: double.maxFinite,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'es_ES').format(focusedMonth).toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: dayWidgets,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, selected.toList()..sort((a, b) => a.compareTo(b))),
            child: Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

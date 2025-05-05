import 'package:flutter/material.dart';

Map<Color, double> calcularColoresDelDia(DateTime date, Map<DateTime, Map<String, dynamic>> dayData) {
  final mediaList = dayData[date]?['media'] ?? [];
  final Map<Color, double> colorSum = {};

  for (final media in mediaList) {
    colorSum[media.color1] = (colorSum[media.color1] ?? 0) + (media.color2 == null ? 1.0 : media.percentage);
    if (media.color2 != null) {
      colorSum[media.color2!] = (colorSum[media.color2!] ?? 0) + (1.0 - media.percentage);
    }
  }

  final sorted = colorSum.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return {for (var e in sorted) e.key: e.value};
}

Color getColor1ForDay(int day, DateTime focusedDate, Map<DateTime, Map<String, dynamic>> dayData) {
  final date = DateTime(focusedDate.year, focusedDate.month, day);
  return getColor1ForDate(date, dayData);
}

Color? getColor2ForDay(int day, DateTime focusedDate, Map<DateTime, Map<String, dynamic>> dayData) {
  final date = DateTime(focusedDate.year, focusedDate.month, day);
  return getColor2ForDate(date, dayData);
}

double getPercentageForDay(int day, DateTime focusedDate, Map<DateTime, Map<String, dynamic>> dayData) {
  final date = DateTime(focusedDate.year, focusedDate.month, day);
  return getPercentageForDate(date, dayData);
}

Color getColor1ForDate(DateTime date, Map<DateTime, Map<String, dynamic>> dayData) {
  final colores = calcularColoresDelDia(date, dayData);
  return colores.isNotEmpty ? colores.keys.first : Colors.grey.shade300;
}

Color? getColor2ForDate(DateTime date, Map<DateTime, Map<String, dynamic>> dayData) {
  final colores = calcularColoresDelDia(date, dayData);
  return colores.length > 1 ? colores.keys.elementAt(1) : null;
}

double getPercentageForDate(DateTime date, Map<DateTime, Map<String, dynamic>> dayData) {
  final colores = calcularColoresDelDia(date, dayData);
  if (colores.length >= 2) {
    final total = colores.values.elementAt(0) + colores.values.elementAt(1);
    return colores.values.elementAt(0) / total;
  }
  return 1.0;
}

import 'package:flutter/material.dart';

const Color softYellow = Color(0xFFF4C430); // Alegría - amarillo dorado
const Color softRed = Color.fromARGB(255, 253, 27, 27); // Ira - rojo fuerte
const Color softBlue = Colors.blueAccent; // Tristeza - azul vivo
const Color softPink = Color.fromARGB(255, 250, 127, 182); // Enamoramiento - rosa intenso
const Color softOrange = Color.fromARGB(255, 255, 168, 38); // Ansiedad - naranja mandarina
const Color softPurple = Colors.purple; // Miedo - morado fuerte

final List<Color> availableColors = [
  softYellow,
  softRed,
  softBlue,
  softPink,
  softOrange,
  softPurple,
];

final Map<Color, String> colorToEmotion = {
  softYellow: 'Alegría',
  softRed: 'Ira',
  softBlue: 'Tristeza',
  softPink: 'Enamoramiento',
  softOrange: 'Ansiedad',
  softPurple: 'Miedo',
};

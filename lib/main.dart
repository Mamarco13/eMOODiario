import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'calendar_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await Hive.initFlutter(); // Inicializa Hive en el dispositivo
  await Hive.openBox('emotionsBox'); // Abre o crea la caja donde guardarás los días

  runApp(EmocionesApp());
}

class EmocionesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Helvetica'),
      home: CalendarScreen(),
    );
  }
}

import 'package:flutter/material.dart';

void showFAQDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Preguntas Frecuentes'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🖼️ ¿Qué es el preview?\n"),
            Text("Es el marco donde se muestra la vista previa de los recuerdos de ese día.\nPara ampliar los recuerdos basta con darle un toque y accederás a una pantalla completa donde descargar de nuevo las fotos o simplemente verlas más a detalle.\nCon dos toques sobre el preview accederás a la pantalla de edición de ese día.\n"),
            Text("📷 ¿Cuántos archivos multimedia puedo subir al día?\n"),
            Text("Hasta 3 archivos por día.\n\n"),
            Text("🎨 ¿Cómo se calculan los colores del día?\n"),
            Text("Los colores representan tus emociones dominantes según lo que elijas al subir multimedia.\nEl color más representativo de tu mes será también el que se use para pintar el fondo del mismo.\n"),
            Text("🎞 ¿Cómo creo un video recuerdo?\n"),
            Text("Pulsa 'Crear Video' y selecciona las opciones de días, duración, filtro de emociones, orden aleatorio y música."),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cerrar"),
        ),
      ],
    ),
  );
}

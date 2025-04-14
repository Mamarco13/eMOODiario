// dual_emotion_circle.dart
import 'package:flutter/material.dart';

class DualEmotionCircle extends StatelessWidget {
  final Color color1;
  final Color color2;
  final int day;
  final double percentage; // porcentaje de color1

  const DualEmotionCircle({
    required this.color1,
    required this.color2,
    required this.day,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(40, 40),
          painter: _DualCirclePainter(color1, color2, percentage),
        ),
        Text(
          '$day',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DualCirclePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double percentage; // porcentaje de color1 (0.0 a 1.0)

  _DualCirclePainter(this.color1, this.color2, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final width1 = size.width * percentage;
    final width2 = size.width * (1 - percentage);

    final rect1 = Rect.fromLTWH(0, 0, width1, size.height);
    final rect2 = Rect.fromLTWH(width1, 0, width2, size.height);

    final rrect1 = RRect.fromRectAndRadius(rect1, Radius.circular(size.width / 2));
    final rrect2 = RRect.fromRectAndRadius(rect2, Radius.circular(size.width / 2));

    canvas.drawRRect(rrect1, paint1);
    canvas.drawRRect(rrect2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

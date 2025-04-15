import 'package:flutter/material.dart';
import 'dart:math';

class EmotionGlassDay extends StatefulWidget {
  final int day;
  final Color color1;
  final Color? color2;
  final double percentage;
  final bool animate;
  final double scaleHeight; // 👈 nuevo parámetro

  const EmotionGlassDay({
    Key? key,
    required this.day,
    required this.color1,
    this.color2,
    this.percentage = 1.0,
    this.animate = true,
    this.scaleHeight = 1.0, // 👈 valor por defecto
  }) : super(key: key);

  @override
  State<EmotionGlassDay> createState() => _EmotionGlassDayState();
}

class _EmotionGlassDayState extends State<EmotionGlassDay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: widget.animate && _controller != null
                ? AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(50, 50),
                        painter: _WavePainter(
                          color1: widget.color1,
                          color2: widget.color2,
                          percentage: widget.percentage,
                          animationValue: _controller!.value,
                          scaleHeight: widget.scaleHeight, // 👈 aquí
                        ),
                      );
                    },
                  )
                : CustomPaint(
                    size: Size(50, 50),
                    painter: _WavePainter(
                      color1: widget.color1,
                      color2: widget.color2,
                      percentage: widget.percentage,
                      animationValue: 0.0,
                      scaleHeight: widget.scaleHeight, // 👈 aquí
                    ),
                  ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
          ),
          Text(
            '${widget.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color1;
  final Color? color2;
  final double percentage;
  final double animationValue;
  final double scaleHeight; // 👈 nuevo

  _WavePainter({
    required this.color1,
    this.color2,
    required this.percentage,
    required this.animationValue,
    required this.scaleHeight, // 👈 obligatorio
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double fillHeight = size.height * 0.95 * scaleHeight; // 👈 ajuste aquí
    final double height1 = fillHeight * percentage;

    final waveHeight = 3.0;
    final waveLength = size.width / 1.5;
    final path1 = Path();
    final path2 = Path();

    if (color2 != null) {
      path2.moveTo(0, size.height - fillHeight);
      for (double x = 0; x <= size.width; x++) {
        path2.lineTo(
          x,
          size.height - fillHeight +
              sin((x / waveLength + animationValue * 2 * pi)) * waveHeight,
        );
      }
      path2.lineTo(size.width, size.height);
      path2.lineTo(0, size.height);
      path2.close();
      canvas.drawPath(path2, Paint()..color = color2!);
    }

    path1.moveTo(0, size.height - height1);
    for (double x = 0; x <= size.width; x++) {
      path1.lineTo(
        x,
        size.height - height1 +
            sin((x / waveLength + animationValue * 2 * pi)) * waveHeight,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, Paint()..color = color1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

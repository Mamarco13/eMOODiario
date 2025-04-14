import 'package:flutter/material.dart';

class AnimatedBubble extends StatefulWidget {
  final Color color;
  final int day;

  const AnimatedBubble({required this.color, required this.day});

  @override
  _AnimatedBubbleState createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          // Aquí podrías navegar al detalle del día
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.day}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PremiumCrownIcon extends StatelessWidget {
  final double size;

  const PremiumCrownIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PremiumCrownPainter(color: const Color(0xFFFFC107)),
    );
  }
}

class _PremiumCrownPainter extends CustomPainter {
  final Color color;

  const _PremiumCrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFB7791F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeJoin = StrokeJoin.round;

    final crown = Path()
      ..moveTo(size.width * 0.12, size.height * 0.74)
      ..lineTo(size.width * 0.2, size.height * 0.32)
      ..lineTo(size.width * 0.38, size.height * 0.52)
      ..lineTo(size.width * 0.5, size.height * 0.18)
      ..lineTo(size.width * 0.62, size.height * 0.52)
      ..lineTo(size.width * 0.8, size.height * 0.32)
      ..lineTo(size.width * 0.88, size.height * 0.74)
      ..close();

    final base = RRect.fromLTRBR(
      size.width * 0.14,
      size.height * 0.68,
      size.width * 0.86,
      size.height * 0.86,
      Radius.circular(size.width * 0.08),
    );

    canvas.drawPath(crown, paint);
    canvas.drawPath(crown, stroke);
    canvas.drawRRect(base, paint);
    canvas.drawRRect(base, stroke);
  }

  @override
  bool shouldRepaint(covariant _PremiumCrownPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

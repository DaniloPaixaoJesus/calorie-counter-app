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
    final crownRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF6C2),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(crownRect)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFF9A6A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeJoin = StrokeJoin.round;

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    final gemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE082), Color(0xFFFFC107)],
      ).createShader(crownRect)
      ..style = PaintingStyle.fill;

    final crown = Path()
      ..moveTo(size.width * 0.12, size.height * 0.74)
      ..lineTo(size.width * 0.2, size.height * 0.34)
      ..lineTo(size.width * 0.37, size.height * 0.56)
      ..lineTo(size.width * 0.5, size.height * 0.17)
      ..lineTo(size.width * 0.63, size.height * 0.56)
      ..lineTo(size.width * 0.8, size.height * 0.34)
      ..lineTo(size.width * 0.88, size.height * 0.74)
      ..close();

    final base = RRect.fromLTRBR(
      size.width * 0.14,
      size.height * 0.68,
      size.width * 0.86,
      size.height * 0.86,
      Radius.circular(size.width * 0.08),
    );

    final shadowPath = Path()
      ..addRRect(
        RRect.fromLTRBR(
          size.width * 0.18,
          size.height * 0.74,
          size.width * 0.82,
          size.height * 0.9,
          Radius.circular(size.width * 0.08),
        ),
      );

    final shadowPaint = Paint()
      ..color = const Color(0xFF8D5A0A).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(crown, crownPaint);
    canvas.drawPath(crown, stroke);
    canvas.drawRRect(base, crownPaint);
    canvas.drawRRect(base, stroke);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.28),
        width: size.width * 0.1,
        height: size.width * 0.1,
      ),
      gemPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.27, size.height * 0.42),
        width: size.width * 0.08,
        height: size.width * 0.08,
      ),
      gemPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.73, size.height * 0.42),
        width: size.width * 0.08,
        height: size.width * 0.08,
      ),
      gemPaint,
    );

    final shinePath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.6,
        size.width * 0.78,
        size.height * 0.68,
      )
      ..lineTo(size.width * 0.72, size.height * 0.73)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.67,
        size.width * 0.28,
        size.height * 0.73,
      )
      ..close();

    canvas.drawPath(shinePath, shine);
  }

  @override
  bool shouldRepaint(covariant _PremiumCrownPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

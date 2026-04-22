import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 스플래시/AppBar 등에서 공통으로 쓰는 PhotoShield 로고 마크.
///
/// 외부 SVG/PNG 자산 없이 [CustomPaint] 와 아이콘만으로 동일한 룩을 그린다.
class PhotoShieldLogoMark extends StatelessWidget {
  final double size;
  final Color shieldColor;
  final Color lensColor;

  const PhotoShieldLogoMark({
    super.key,
    this.size = 40,
    this.shieldColor = Colors.white,
    this.lensColor = const Color(0xFF1E40AF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(shieldColor: shieldColor),
        child: Center(
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: lensColor,
              shape: BoxShape.circle,
              border: Border.all(color: shieldColor, width: size * 0.04),
            ),
            child: Center(
              child: Container(
                width: size * 0.12,
                height: size * 0.12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color shieldColor;
  _ShieldPainter({required this.shieldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = shieldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h * 0.05);
    path.lineTo(w * 0.92, h * 0.20);
    path.lineTo(w * 0.92, h * 0.55);
    path.quadraticBezierTo(w * 0.92, h * 0.92, w * 0.5, h * 0.97);
    path.quadraticBezierTo(w * 0.08, h * 0.92, w * 0.08, h * 0.55);
    path.lineTo(w * 0.08, h * 0.20);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.shieldColor != shieldColor;
}

/// AppBar 의 leading 영역에 들어가는 작은 로고 + "PhotoShield" 텍스트.
class PhotoShieldAppBarTitle extends StatelessWidget {
  final Color textColor;
  final Color subTextColor;
  final Color shieldColor;

  const PhotoShieldAppBarTitle({
    super.key,
    this.textColor = Colors.white,
    this.subTextColor = Colors.white,
    this.shieldColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhotoShieldLogoMark(
          size: 30,
          shieldColor: shieldColor,
          lensColor: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PhotoShield',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              'KOREA',
              style: TextStyle(
                color: subTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

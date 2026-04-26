import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo "GoodMusic" - sóng âm + nốt nhạc, vẽ bằng CustomPainter,
/// có animation pulse + xoay nhẹ.
class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool spin;
  const AnimatedLogo({super.key, this.size = 120, this.spin = false});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _rot;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _rot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.spin) _rot.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _rot]),
      builder: (_, __) {
        final scale = 1 + _pulse.value * 0.06;
        final angle = _rot.value * 2 * pi;
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _LogoPainter(progress: _pulse.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double progress;
  _LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Vòng tròn gradient nền
    final ringPaint = Paint()
      ..shader = AppColors.brandGradient.createShader(
        Rect.fromCircle(center: c, radius: r),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, ringPaint);

    // Lỗ giữa
    final hole = Paint()..color = const Color(0xFF0A0C12);
    canvas.drawCircle(c, r * 0.55, hole);

    // Sóng âm
    final wavePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;

    final bars = [0.3, 0.55, 0.8, 0.55, 0.3];
    final spacing = r * 0.18;
    for (var i = 0; i < bars.length; i++) {
      final h = r * (bars[i] * (0.7 + 0.3 * progress));
      final x = c.dx + (i - 2) * spacing;
      canvas.drawLine(
        Offset(x, c.dy - h / 2),
        Offset(x, c.dy + h / 2),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.progress != progress;
}

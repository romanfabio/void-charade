import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A one-shot burst of falling confetti, drawn with a [CustomPainter] (no
/// package). Ignores touches, so it can sit on top of any screen.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particles = 90,
    this.duration = const Duration(milliseconds: 3600),
  });

  final int particles;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  // Fixed seed: the same pleasant burst every time, and deterministic in tests.
  late final List<_Piece> _pieces = _makePieces(widget.particles, math.Random(7));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_pieces, _controller),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.drift,
    required this.speed,
    required this.delay,
    required this.spin,
    required this.phase,
    required this.wobble,
    required this.size,
    required this.color,
    required this.round,
  });

  final double x; // start, fraction of width
  final double drift; // sideways travel, fraction of width
  final double speed; // fall speed multiplier
  final double delay; // fraction of the timeline before it appears
  final double spin;
  final double phase;
  final double wobble;
  final double size;
  final Color color;
  final bool round;
}

const _palette = [
  AppColors.magenta,
  AppColors.orange,
  AppColors.cyan,
  AppColors.violet,
  Color(0xFFFFD43B),
  Colors.white,
];

List<_Piece> _makePieces(int count, math.Random r) => [
      for (var i = 0; i < count; i++)
        _Piece(
          x: r.nextDouble(),
          drift: (r.nextDouble() - 0.5) * 0.3,
          speed: 0.75 + r.nextDouble() * 0.6,
          delay: r.nextDouble() * 0.3,
          spin: (r.nextDouble() - 0.5) * 14,
          phase: r.nextDouble() * math.pi * 2,
          wobble: 1 + r.nextDouble() * 3,
          size: 7 + r.nextDouble() * 8,
          color: _palette[r.nextInt(_palette.length)],
          round: r.nextBool(),
        ),
    ];

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();

    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;

      final x = (p.x + p.drift * local + 0.03 * math.sin(local * p.wobble * math.pi * 2 + p.phase)) *
          size.width;
      final y = (-0.05 + p.speed * local * 1.2) * size.height;
      final fade = local > 0.8 ? (1 - local) / 0.2 : 1.0;

      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.phase + p.spin * local);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.pieces != pieces;
}

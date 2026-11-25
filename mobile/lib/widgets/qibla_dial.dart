import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

class QiblaDial extends StatelessWidget {
  const QiblaDial({super.key, required this.bearing, this.size = 92});

  final double bearing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final degrees = bearing.round() % 360;
    return Semantics(
      label: l10n.qiblaBearing('$degrees'),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _QiblaPainter(
                bearing: degrees.toDouble(),
                line: scheme.outline,
                accent: scheme.primary,
                muted: scheme.onSurfaceVariant,
                surface: scheme.surface,
                textStyle: Theme.of(context).textTheme.labelSmall!,
              ),
              child: Center(
                child: Icon(
                  Icons.mosque_rounded,
                  size: 17,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$degrees°',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaPainter extends CustomPainter {
  _QiblaPainter({
    required this.bearing,
    required this.line,
    required this.accent,
    required this.muted,
    required this.surface,
    required this.textStyle,
  });

  final double bearing;
  final Color line;
  final Color accent;
  final Color muted;
  final Color surface;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = line;
    canvas.drawCircle(center, radius, ring);

    final tick = Paint()
      ..strokeWidth = 1
      ..color = muted.withValues(alpha: 0.6);
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final inner = radius - (i % 6 == 0 ? 7 : 3);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        tick,
      );
    }

    const directions = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final offset = Offset(math.cos(angle), math.sin(angle)) * (radius - 14);
      final painter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: textStyle.copyWith(
            color: i == 0 ? accent : muted,
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center + offset - Offset(painter.width / 2, painter.height / 2),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bearing * math.pi / 180);
    final start = -radius * 0.3;
    final tip = -(radius - 30);
    final arrow = Path()
      ..moveTo(0, start)
      ..lineTo(4.5, tip + 9)
      ..lineTo(0, tip)
      ..lineTo(-4.5, tip + 9)
      ..close();
    canvas.drawPath(arrow, Paint()..color = accent);
    final marker = Rect.fromLTWH(-5, -(radius - 22), 10, 10);
    canvas.drawRect(marker, Paint()..color = surface);
    canvas.drawRect(
      marker,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QiblaPainter oldDelegate) =>
      oldDelegate.bearing != bearing ||
      oldDelegate.accent != accent ||
      oldDelegate.line != line;
}

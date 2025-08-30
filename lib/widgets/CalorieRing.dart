import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:get/get.dart';

class CalorieRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double? size;
  final double? strokeWidth;
  final Color? progressColor;

  const CalorieRing({
    super.key,
    required this.progress,
    this.size,
    this.strokeWidth,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawSize = size ?? math.min(constraints.maxWidth, constraints.maxHeight);
        final circleSize = rawSize * 1.12;
        final stroke = strokeWidth ?? math.max(6.0, rawSize * 0.09);

        return SizedBox(
          width: circleSize,
          height: circleSize,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 450),
            builder: (context, animatedProgress, _) {
              return CustomPaint(
                painter: RoundedArcPainter(
                  progress: animatedProgress,
                  strokeWidth: stroke,
                  backgroundColor: context.theme.brightness == Brightness.dark
                      ? AppColor.neutralGrey800
                      : AppColor.neutralGrey200,
                  progressColor: progressColor ?? AppColor.primaryOrange,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class RoundedArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  RoundedArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RoundedArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}

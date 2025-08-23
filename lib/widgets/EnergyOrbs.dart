import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';

class EnergyOrbs extends StatelessWidget {
  const EnergyOrbs({
    super.key,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatsConsumed,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatsGoal,
  });

  final int proteinConsumed;
  final int carbsConsumed;
  final int fatsConsumed;
  final int proteinGoal;
  final int carbsGoal;
  final int fatsGoal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Always try to place orbs on a single horizontal line.
        // Use a horizontal scroll view as a graceful fallback on very narrow devices.
        final children = [
          EnergyOrb(
            labelKey: 'Protein',
            consumed: proteinConsumed,
            goal: proteinGoal,
            color: const Color(0xFF4A90E2),
            size: 78.0,
          ),
          EnergyOrb(
            labelKey: 'Carbs',
            consumed: carbsConsumed,
            goal: carbsGoal,
            color: const Color(0xFFFF8C42),
            size: 78.0,
          ),
          EnergyOrb(
            labelKey: 'Fats',
            consumed: fatsConsumed,
            goal: fatsGoal,
            color: const Color(0xFFFFD700),
            size: 78.0,
          ),
        ];

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            children[0],
            const SizedBox(width: 12),
            children[1],
            const SizedBox(width: 12),
            children[2],
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}

class EnergyOrb extends StatefulWidget {
  const EnergyOrb({
    super.key,
    required this.labelKey,
    required this.consumed,
    required this.goal,
    required this.color,
  this.size = 78.0,
  });

  final String labelKey;
  final int consumed;
  final int goal;
  final Color color;
  final double size;

  @override
  State<EnergyOrb> createState() => _EnergyOrbState();
}

class _EnergyOrbState extends State<EnergyOrb> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))
      ..repeat();
    _sparkle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _breathe.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal <= 0 ? 1 : widget.goal;
    final targetProgress = (widget.consumed / goal).clamp(0.0, 1.0);

    // Trigger a short sparkle pulse when just hit 100%
    if (targetProgress >= 1.0 && !_sparkle.isAnimating && _sparkle.value == 0) {
      _sparkle.forward(from: 0);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetProgress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_breathe, _sparkle]),
          builder: (context, __) {
            final orbSize = widget.size;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Orb container (flat) with optional done overlay when complete
                Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    // Glow removed: flat orb
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // base painted orb
                      CustomPaint(
                        size: Size(orbSize, orbSize),
                        painter: _OrbPainter(
                          progress: progress,
                          color: widget.color,
                          t: _breathe.value,
                          sparkle: _sparkle.value,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      // show a solid circular badge with a white check when complete
                      if (progress >= 1.0)
                        Container(
                          width: orbSize * 0.54,
                          height: orbSize * 0.54,
                          decoration: BoxDecoration(
                            color: widget.color, // use orb color for badge background
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: orbSize * 0.36,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.labelKey.tr,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.consumed}${'gram_unit'.tr} / ${widget.goal}${'gram_unit'.tr}',
                  style: context.textTheme.labelLarge?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.color,
    required this.t,
    required this.sparkle,
    required this.isDark,
  });

  final double progress; // 0..1
  final Color color;
  final double t; // 0..1 breathing phase
  final double sparkle; // 0..1 sparkle pulse
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

  // Base orb body: use a flat solid color with reduced opacity
  final basePaint = Paint()..color = color.withOpacity(0.3);
  canvas.drawCircle(center, radius, basePaint);

  // Inner glow removed — keeping only the colored fill and liquid wave.

    // Liquid fill with wavy top
    final liquidHeight = (2 * radius) * progress;
    final topY = center.dy + radius - liquidHeight;
    final amp = 4.0; // wave amplitude
    final cycles = 1.2; // waves across width

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(path);

  // Use the same flat color for the fill area with reduced opacity so background is less intense.
  final fillPaint = Paint()..color = color.withOpacity(0.3);

    // Draw filled area up to wave top
    final liquidPath = Path()
      ..moveTo(center.dx - radius, center.dy + radius)
      ..lineTo(center.dx - radius, topY);
    for (double x = -radius; x <= radius; x++) {
      final wx = (x + radius) / (2 * radius);
      final y = topY + amp * math.sin((wx * cycles * 2 * math.pi) + t * 2 * math.pi);
      liquidPath.lineTo(center.dx + x, y);
    }
    liquidPath
      ..lineTo(center.dx + radius, center.dy + radius)
      ..close();
    canvas.drawPath(liquidPath, fillPaint);

  // Specular highlight removed per user request — keeping the orb visuals focused on colored fill and wave.

    // Sparkle pulse when full
      if (progress >= 1.0 && sparkle > 0) {
      final sOpacity = (1 - sparkle).clamp(0.0, 1.0);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColor.primaryOrange.withOpacity(0.6 * sOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, radius * (1 + 0.15 * sparkle), ring);

      // Few sparkles around
      final sparkCount = 6;
  for (int i = 0; i < sparkCount; i++) {
        final angle = (2 * math.pi / sparkCount) * i + sparkle * 2 * math.pi;
        final r = radius * (0.95 + 0.1 * math.sin(i + sparkle * 2 * math.pi));
        final pos = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
  canvas.drawCircle(pos, 2.0 + 1.0 * (1 - sparkle), Paint()..color = AppColor.primaryOrange.withOpacity(0.9 * sOpacity));
      }
    }

    canvas.restore();

  // Outer rim removed to eliminate subtle shadow/glow.
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.t != t ||
        old.sparkle != sparkle ||
        old.isDark != isDark;
  }
}

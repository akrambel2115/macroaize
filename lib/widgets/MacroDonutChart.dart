import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';

/// Interactive multi-color donut chart for Protein / Carbs / Fats breakdown and progress.
/// - Segments sized by target grams share of total daily macros.
/// - Animated sweep for progress.
/// - Tap/Hover to highlight and show details.
/// - Center shows remaining grams or title/celebration.
class MacroDonutChart extends StatefulWidget {
  const MacroDonutChart({
    super.key,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatsConsumed,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatsGoal,
    this.showTitleInsteadOfRemaining = false,
  });

  final int proteinConsumed;
  final int carbsConsumed;
  final int fatsConsumed;
  final int proteinGoal;
  final int carbsGoal;
  final int fatsGoal;
  final bool showTitleInsteadOfRemaining;

  @override
  State<MacroDonutChart> createState() => _MacroDonutChartState();
}

class _MacroDonutChartState extends State<MacroDonutChart> {
  // 0: Protein, 1: Carbs, 2: Fats, -1: none
  int _hoveredIndex = -1;
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final totalGoal = (widget.proteinGoal + widget.carbsGoal + widget.fatsGoal).clamp(0, 1000000);
    final safeTotalGoal = totalGoal == 0 ? 1 : totalGoal;

    final goals = [widget.proteinGoal, widget.carbsGoal, widget.fatsGoal];
    final consumed = [widget.proteinConsumed, widget.carbsConsumed, widget.fatsConsumed];
    final colors = const [
      Color(0xFF4A90E2), // Protein - Neon Blue
      Color(0xFFFF8C42), // Carbs - Neon Orange
      Color(0xFFFFD700), // Fats - Neon Yellow
    ];
    final labels = [
      'Protein'.tr,
      'Carbs'.tr,
      'Fats'.tr,
    ];

    final remainingGrams = math.max(0, widget.proteinGoal - widget.proteinConsumed)
        + math.max(0, widget.carbsGoal - widget.carbsConsumed)
        + math.max(0, widget.fatsGoal - widget.fatsConsumed);

    // Center text mode
    final centerModeTitle = widget.showTitleInsteadOfRemaining;
    final reached = remainingGrams <= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        // Keep chart roughly square; limit height sensibly
  final chartSize = math.min(maxW, 260.0);
  final stroke = math.max(12.0, chartSize * 0.14); // Responsive thickness
  final gapRadians = 6 * math.pi / 180; // 6 degrees gaps

        // Details card below center
        Widget details() {
          final idx = _selectedIndex >= 0 ? _selectedIndex : _hoveredIndex;
          if (idx < 0) return const SizedBox.shrink();
          final g = goals[idx];
          final c = consumed[idx];
          final pct = g > 0 ? ((c / g) * 100).clamp(0, 999).round() : 0;
          final text = '${labels[idx]}: $c${'gram_unit'.tr} / $g${'gram_unit'.tr} ($pct%)';
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          );
        }

        // Center content widget
        Widget centerContent() {
          if (centerModeTitle) {
            return Text(
              'daily_macros'.tr,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            );
          }
          if (reached) {
            return Text(
              'daily_macros_reached'.tr,
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            );
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: remainingGrams.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.round().toString(),
                    style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${'gram_unit'.tr} ${'Remaining'.tr}',
                    style: context.textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              );
            },
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart
            Center(
              child: MouseRegion(
                onHover: (event) => _updateHoverFromEvent(context, event, stroke, chartSize, goals, safeTotalGoal, gapRadians),
                onExit: (_) => setState(() => _hoveredIndex = -1),
                child: GestureDetector(
                  onTapDown: (details) {
                    final idx = _hitTestIndex(context, details.globalPosition, stroke, chartSize, goals, safeTotalGoal, gapRadians);
                    setState(() => _selectedIndex = idx);
                  },
                  child: SizedBox(
                    height: chartSize,
                    width: chartSize,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      builder: (context, anim, _) {
                        return CustomPaint(
                          painter: _MacroDonutPainter(
                            goals: goals,
                            consumed: consumed,
                            totalGoal: safeTotalGoal,
                            colors: colors,
                            strokeWidth: stroke,
                            backgroundTrackColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06),
                            gapRadians: gapRadians,
                            progressFactor: anim,
                            hoveredIndex: _hoveredIndex,
                            selectedIndex: _selectedIndex,
                          ),
                          child: Center(child: centerContent()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Details line
            details(),
          ],
        );
      },
    );
  }

  void _updateHoverFromEvent(
    BuildContext context,
    PointerHoverEvent event,
    double stroke,
    double chartSize,
    List<int> goals,
    int totalGoal,
    double gapRadians,
  ) {
    final idx = _hitTestIndex(context, event.position, stroke, chartSize, goals, totalGoal, gapRadians);
    if (idx != _hoveredIndex) {
      setState(() => _hoveredIndex = idx);
    }
  }

  int _hitTestIndex(
    BuildContext context,
    Offset globalPos,
    double stroke,
    double chartSize,
    List<int> goals,
    int totalGoal,
    double gapRadians,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return -1;
    final local = box.globalToLocal(globalPos);
    // Center of the chart inside this box
    final center = Offset(box.size.width / 2, 0) + Offset(0, chartSize / 2);
    final diff = local - center;
    final r = diff.distance;
    final outerR = chartSize / 2;
    final innerR = outerR - stroke;
    if (r < innerR - 8 || r > outerR + 8) {
      return -1;
    }

    double angle = math.atan2(diff.dy, diff.dx); // -pi..pi with 0 along +x
    angle = angle < -math.pi / 2 ? angle + 2 * math.pi : angle; // normalize
    // shift so 0 is at top (-pi/2)
    double a = angle + math.pi / 2;
    if (a < 0) a += 2 * math.pi;

    final totalAngle = 2 * math.pi;
    // Build segments
    double start = 0;
    for (int i = 0; i < 3; i++) {
      final sweep = totalAngle * (goals[i] / totalGoal) - gapRadians;
      final end = start + math.max(0, sweep);
      if (a >= start && a <= end) {
        return i;
      }
      start = end + gapRadians;
    }
    return -1;
  }
}

class _MacroDonutPainter extends CustomPainter {
  _MacroDonutPainter({
    required this.goals,
    required this.consumed,
    required this.totalGoal,
    required this.colors,
    required this.strokeWidth,
    required this.backgroundTrackColor,
    required this.gapRadians,
    required this.progressFactor,
    required this.hoveredIndex,
    required this.selectedIndex,
  });

  final List<int> goals;
  final List<int> consumed;
  final int totalGoal;
  final List<Color> colors;
  final double strokeWidth;
  final Color backgroundTrackColor;
  final double gapRadians;
  final double progressFactor; // 0..1 animation factor
  final int hoveredIndex;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final trackRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Base neutral ring
    final basePaint = Paint()
      ..color = backgroundTrackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(trackRect, 0, 2 * math.pi, false, basePaint);

    // Segment backgrounds (light tint by macro)
    double start = 0;
    final totalAngle = 2 * math.pi;
    for (int i = 0; i < 3; i++) {
      final share = goals[i] <= 0 || totalGoal <= 0 ? 0.0 : goals[i] / totalGoal;
      final double sweep = math.max(0.0, totalAngle * share - gapRadians);
      if (sweep > 0) {
        final segBg = Paint()
          ..color = colors[i].withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;
        canvas.drawArc(trackRect, -math.pi / 2 + start, sweep, false, segBg);
      }
      start += sweep + gapRadians;
    }

    // Consumed overlays
    start = 0;
    for (int i = 0; i < 3; i++) {
      final share = goals[i] <= 0 || totalGoal <= 0 ? 0.0 : goals[i] / totalGoal;
      final double sweep = math.max(0.0, totalAngle * share - gapRadians);
      if (sweep <= 0) {
        start += math.max(0, sweep) + gapRadians;
        continue;
      }

  final double progress = goals[i] > 0 ? (consumed[i] / goals[i]).clamp(0.0, 1.0) : 0.0;
      final progressSweep = sweep * progress * progressFactor;

      // Glow layer when hovered/selected
      final isActive = (i == hoveredIndex) || (i == selectedIndex);
      if (isActive && progressSweep > 0) {
        final glow = Paint()
          ..color = colors[i].withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth + 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(trackRect, -math.pi / 2 + start, progressSweep, false, glow);
      }

      final segPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;
      canvas.drawArc(trackRect, -math.pi / 2 + start, progressSweep, false, segPaint);

      start += sweep + gapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter oldDelegate) {
    return oldDelegate.goals != goals ||
        oldDelegate.consumed != consumed ||
        oldDelegate.totalGoal != totalGoal ||
        oldDelegate.colors != colors ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundTrackColor != backgroundTrackColor ||
        oldDelegate.gapRadians != gapRadians ||
        oldDelegate.progressFactor != progressFactor ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/get.dart';

class WeightJourney extends StatefulWidget {
  const WeightJourney({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    this.onEditCurrent,
    this.onEditGoal,
  });

  final int currentWeight;
  final int goalWeight;
  final VoidCallback? onEditCurrent;
  final VoidCallback? onEditGoal;

  @override
  State<WeightJourney> createState() => _WeightJourneyState();
}

class _WeightJourneyState extends State<WeightJourney>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  double _prevProgress = 0;

  double get _progress {
    final diff = (widget.goalWeight - widget.currentWeight).abs();
    final denom =
        widget.currentWeight > widget.goalWeight
            ? widget.currentWeight.toDouble()
            : widget.goalWeight.toDouble();
    if (denom <= 0) return 0.0;
    return (1 - (diff / denom)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _prevProgress = _progress;
    _progressAnim = Tween<double>(
      begin: _prevProgress,
      end: _prevProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant WeightJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _progress;
    _progressAnim = Tween<double>(
      begin: _prevProgress,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller
      ..value = 0
      ..forward();
    _prevProgress = newProgress;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.currentWeight;
    final end = widget.goalWeight;
    final total = (end - start).abs();
    final maxMilestones = 7;
    final milestones = <int>[];
    if (total == 0) {
      milestones.add(start);
    } else if (total <= maxMilestones - 1) {
      final step = start <= end ? 1 : -1;
      for (int v = start; step > 0 ? v <= end : v >= end; v += step) {
        milestones.add(v);
      }
    } else {
      final steps = maxMilestones - 1;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final value = (start + (end - start) * t).round();
        if (milestones.isEmpty || milestones.last != value) {
          milestones.add(value);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const lineHeight = 6.0;
        const avatarSize = 28.0;
        const paddingH = 8.0;
        const containerHeight = 99.0;
        final centerY = 30.0;
        return SizedBox(
          height: containerHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                left: paddingH,
                right: paddingH,
                child: CustomPaint(
                  painter: _JourneyPainter(
                    progressAnim: _progressAnim,
                    milestones: milestones,
                    start: start,
                    end: end,
                    lineHeight: lineHeight,
                    centerY: centerY,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: centerY + 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current column (left)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabelPill(
                            text: 'Current',
                            color: AppColor.secondary,
                            onTap: widget.onEditCurrent,
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                            child: Text(
                              '$start${'kg'.tr}',
                              key: ValueKey<int>(start),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppColor.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Goal column (right)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _LabelPill(
                            text: 'Goal',
                            color: AppColor.primaryOrange,
                            onTap: widget.onEditGoal,
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                            child: Text(
                              '$end${'kg'.tr}',
                              key: ValueKey<int>(end),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppColor.primaryOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  final usableWidth = width - paddingH * 2;
                  final x = (paddingH + usableWidth * _progressAnim.value)
                      .clamp(0.0, width);

                  final left = (x - (avatarSize / 2)).clamp(
                    0.0,
                    width - avatarSize,
                  );
                  final top = (centerY - (avatarSize / 2)).clamp(
                    0.0,
                    containerHeight - avatarSize,
                  );
                  return Positioned(
                    left: left,
                    top: top,
                    child: _AvatarMarker(size: avatarSize),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.progressAnim,
    required this.milestones,
    required this.start,
    required this.end,
    required this.lineHeight,
    required this.centerY,
  }) : super(repaint: progressAnim);

  final Animation<double> progressAnim;
  final List<int> milestones;
  final int start;
  final int end;
  final double lineHeight;
  final double centerY;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = lineHeight / 2;
    final y = centerY;
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - radius, size.width, lineHeight),
      Radius.circular(radius),
    );

    final basePaint = Paint()..color = AppColor.neutralGrey200;
    canvas.drawRRect(baseRect, basePaint);

    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - radius, size.width * progressAnim.value, lineHeight),
      Radius.circular(radius),
    );
    final progressPaint = Paint()..color = AppColor.primaryOrange;
    canvas.drawRRect(progressRect, progressPaint);

    final total = (end - start).abs();
    if (total == 0) return;
    final denom = (end - start).toDouble();
    for (final m in milestones) {
      final tRaw = denom == 0 ? 0.0 : (m - start) / denom;
      final t = tRaw.isNaN || tRaw.isInfinite ? 0.0 : tRaw;
      final x = size.width * t.clamp(0.0, 1.0);
      final reached = t <= progressAnim.value;
      final paint =
          Paint()
            ..color = reached ? AppColor.primaryOrange : AppColor.neutralGrey400
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter oldDelegate) {
    return oldDelegate.milestones != milestones ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.progressAnim.value != progressAnim.value;
  }
}

class _AvatarMarker extends StatelessWidget {
  const _AvatarMarker({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.primaryOrange,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.local_fire_department_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({required this.text, required this.color, this.onTap});
  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text.tr,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.edit_outlined, size: 14, color: color),
        ],
      ],
    );

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: pill,
      );
    }

    return pill;
  }
}

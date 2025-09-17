import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum MacroViz { circle, bar, wave }

class MacroCardTile extends StatefulWidget {
  const MacroCardTile({
    super.key,
    required this.labelKey,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.viz,
  });

  final String labelKey; // Protein, Carbs, Fats
  final int consumed;
  final int goal;
  final Color color;
  final MacroViz viz;

  @override
  State<MacroCardTile> createState() => _MacroCardTileState();
}

class _MacroCardTileState extends State<MacroCardTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal <= 0 ? 1 : widget.goal;
    final endProgress = (widget.consumed / goal).clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: endProgress),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          final scale = 1.0 + 0.03 * math.sin(progress * math.pi);
          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.12),
                    blurRadius: _hovered ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                  if (_hovered)
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 0.5,
                    ),
                ],
                border: Border.all(
                  color: _hovered ? widget.color.withOpacity(0.35) : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MiniViz(progress: progress, color: widget.color, viz: widget.viz, wave: _waveController),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.labelKey.tr,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${widget.consumed}${'gram_unit'.tr}',
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(' / ', style: context.textTheme.titleMedium),
                            Text(
                              '${widget.goal}${'gram_unit'.tr}',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).round()}%',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniViz extends StatelessWidget {
  const _MiniViz({
    required this.progress,
    required this.color,
    required this.viz,
    required this.wave,
  });

  final double progress;
  final Color color;
  final MacroViz viz;
  final Animation<double> wave;

  @override
  Widget build(BuildContext context) {
    final size = 58.0;
    Widget child;
    switch (viz) {
      case MacroViz.circle:
        child = CustomPaint(
          size: Size.square(size),
          painter: _MiniArcPainter(progress: progress, color: color),
        );
        break;
      case MacroViz.bar:
        child = SizedBox(
          width: size + 16,
          height: 16,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case MacroViz.wave:
        child = CustomPaint(
          size: Size(size + 8, size),
          painter: _MiniWavePainter(progress: progress, color: color, t: wave.value),
        );
        break;
    }
    return SizedBox(width: size + 16, height: size, child: Center(child: child));
  }
}

class _MiniArcPainter extends CustomPainter {
  _MiniArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bg = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, 2 * math.pi, false, bg);
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _MiniArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _MiniWavePainter extends CustomPainter {
  _MiniWavePainter({required this.progress, required this.color, required this.t});
  final double progress;
  final Color color;
  final double t; // 0..1 looping

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final h = size.height;
    final w = size.width;
    final level = h * (1 - progress); // higher progress => lower empty area
    final amplitude = 4.0;
    final cycles = 1.5;
    path.moveTo(0, h);
    path.lineTo(0, level);
    for (double x = 0; x <= w; x++) {
      final y = level + amplitude * math.sin((x / w * cycles * 2 * math.pi) + t * 2 * math.pi);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(10)), Paint()..color = Colors.black.withOpacity(0.08));
    canvas.clipRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(10)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.t != t;
}

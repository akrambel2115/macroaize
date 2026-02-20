import 'dart:math';

import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';

class CelebrationStrip extends StatefulWidget {
  const CelebrationStrip({
    super.key,
    required this.message,
    this.height = 44,
    this.showConfetti = true,
  });

  final String message;
  final double height;
  final bool showConfetti;

  @override
  State<CelebrationStrip> createState() => _CelebrationStripState();
}

class _CelebrationStripState extends State<CelebrationStrip>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  AnimationController? _typeCtrl;
  int _visibleChars = 0;

  late final AnimationController _confettiCtrl;
  List<_Particle> _particles = const [];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_entranceCtrl);
    _opacity = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    final typeDuration = Duration(
      milliseconds: 30 * widget.message.length + 300,
    );
    _typeCtrl = AnimationController(vsync: this, duration: typeDuration)
      ..addListener(_updateTypewriter);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() => setState(() {}));

    _particles = List.generate(22, (i) => _Particle.random());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entranceCtrl.forward();
      _typeCtrl?.forward(from: 0);
      if (widget.showConfetti) _confettiCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant CelebrationStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      final c = _typeCtrl;
      if (c != null) {
        c.duration = Duration(milliseconds: 30 * widget.message.length + 300);
        c.forward(from: 0);
      }
      _visibleChars = 0;
    }
    _particles = List.generate(22, (i) => _Particle.random());
    if (widget.showConfetti) _confettiCtrl.forward(from: 0);
    _entranceCtrl.forward(from: 0);
  }

  void _updateTypewriter() {
    final t = _typeCtrl?.value ?? 0.0;
    final len = widget.message.characters.length;
    final chars = (len * Curves.easeOut.transform(t)).clamp(0, len).toInt();
    if (chars != _visibleChars) setState(() => _visibleChars = chars);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _typeCtrl?.removeListener(_updateTypewriter);
    _typeCtrl?.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = AppColor.primaryOrange;
    final textColor = Colors.white;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _opacity,
              child: Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: bgColor,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppColor.primaryOrange)
                          .withValues(alpha: isDark ? 0.4 : 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: _AnimatedWaveUnderline(
                  color: textColor.withValues(alpha: 0.18),
                  child: Text(
                    widget.message.characters.take(_visibleChars).toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showConfetti)
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    progress: _confettiCtrl.value,
                    particles: _particles,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedWaveUnderline extends StatefulWidget {
  const _AnimatedWaveUnderline({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  State<_AnimatedWaveUnderline> createState() => _AnimatedWaveUnderlineState();
}

class _AnimatedWaveUnderlineState extends State<_AnimatedWaveUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _WavePainter(t: _ctrl.value, color: widget.color),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final path = Path();
    final y = size.height - 6;
    final amp = 2.0;
    final len = size.width;
    const waves = 1.5;
    for (double x = 0; x <= len; x += 6) {
      final phase = (x / len) * 2 * pi * waves + t * 2 * pi;
      final dy = sin(phase) * amp;
      if (x == 0) {
        path.moveTo(x, y + dy);
      } else {
        path.lineTo(x, y + dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

class _Particle {
  _Particle({
    required this.origin,
    required this.velocity,
    required this.hue,
    required this.shape,
    required this.size,
  });

  factory _Particle.random() {
    final rnd = _rnd;
    final origin = Offset(
      rnd.nextDouble(),
      rnd.nextDouble() * 0.4 + 0.2,
    );
    final angle = rnd.nextDouble() * 2 * pi;
    final speed = rnd.nextDouble() * 0.35 + 0.2;
    final velocity = Offset(cos(angle), sin(angle)) * speed;
    final hue = rnd.nextDouble();
    final shape = rnd.nextBool() ? _Shape.circle : _Shape.spark;
    final size = rnd.nextDouble() * 3 + 2;
    return _Particle(
      origin: origin,
      velocity: velocity,
      hue: hue,
      shape: shape,
      size: size,
    );
  }

  static final _rnd = Random();
  final Offset origin;
  final Offset velocity;
  final double hue;
  final _Shape shape;
  final double size;
}

enum _Shape { circle, spark }

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});
  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final p = progress;
    for (final part in particles) {
      final life = Curves.easeOut.transform(1 - p);
      final pos = Offset(
        part.origin.dx * size.width + part.velocity.dx * size.width * p,
        // rise up effect
        part.origin.dy * size.height +
            part.velocity.dy * size.height * p * -0.6,
      );

      final alpha = (255 * (life.clamp(0, 1))).toInt();
      final paint =
          Paint()
            ..color = HSVColor.fromAHSV(
              1,
              part.hue * 360,
              0.8,
              1.0,
            ).toColor().withAlpha(alpha);

      switch (part.shape) {
        case _Shape.circle:
          canvas.drawCircle(pos, part.size, paint);
          break;
        case _Shape.spark:
          final path = Path();
          final s = part.size + 1.5;
          path.moveTo(pos.dx, pos.dy - s);
          path.lineTo(pos.dx + s * 0.6, pos.dy + s * 0.6);
          path.lineTo(pos.dx - s * 0.6, pos.dy + s * 0.6);
          path.close();
          canvas.drawPath(path, paint..style = PaintingStyle.fill);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}

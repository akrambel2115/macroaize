import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../SharePrefHelper/share_pref_key.dart';

class TutorialCoachService {
  static final TutorialCoachService _instance =
      TutorialCoachService._internal();
  factory TutorialCoachService() => _instance;
  TutorialCoachService._internal();

  Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // same key as app_tips
    return prefs.getBool(SharePrefKey.hasSeenAppTips) ?? false;
  }

  Future<void> markTutorialAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    // same key as app_tips
    await prefs.setBool(SharePrefKey.hasSeenAppTips, true);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharePrefKey.hasSeenAppTips);
  }

  Future<void> showTutorialIfNeeded(
    BuildContext context,
    List<TutorialStep> steps,
  ) async {
    final hasCompleted = await hasCompletedTutorial();
    if (!hasCompleted && steps.isNotEmpty) {
      // delay for widget render
      await Future.delayed(const Duration(milliseconds: 1200));
      if (context.mounted) {
        showTutorial(context, steps);
      }
    }
  }

  void showTutorial(BuildContext context, List<TutorialStep> steps) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, _, __) => TutorialOverlay(steps: steps),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class TutorialStep {
  final GlobalKey targetKey;
  final String titleKey;
  final String descriptionKey;
  final TooltipPosition position;
  final IconData? icon;

  TutorialStep({
    required this.targetKey,
    required this.titleKey,
    required this.descriptionKey,
    this.position = TooltipPosition.bottom,
    this.icon,
  });
}

enum TooltipPosition { top, bottom, left, right }

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;

  const TutorialOverlay({super.key, required this.steps});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int currentStep = 0;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // fade in after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _visible = true;
      });
    });
  }

  void _nextStep() {
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        _visible = false;
      });
      // fade out then next
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            currentStep++;
            _visible = true;
          });
        }
      });
    } else {
      _completeTutorial();
    }
  }

  void _completeTutorial() async {
    await TutorialCoachService().markTutorialAsCompleted();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[currentStep];
    final targetContext = step.targetKey.currentContext;

    if (targetContext == null) {
      // Widget not found - complete tutorial instead of looping
      debugPrint(
        '⚠️ TutorialCoachService: Target widget not found for step $currentStep. Completing tutorial.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeTutorial());
      return const SizedBox.shrink();
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint(
        '⚠️ TutorialCoachService: RenderBox null for step $currentStep. Completing tutorial.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeTutorial());
      return const SizedBox.shrink();
    }

    final targetSize = renderBox.size;
    final targetPosition = renderBox.localToGlobal(Offset.zero);

    if (targetSize.isEmpty) {
      // Widget has no size - complete tutorial
      debugPrint(
        '⚠️ TutorialCoachService: Target widget empty size for step $currentStep. Completing tutorial.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeTutorial());
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _nextStep, // Tap anywhere to continue
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // spotlight overlay
              AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: SpotlightPainter(
                      targetRect: Rect.fromLTWH(
                        targetPosition.dx,
                        targetPosition.dy,
                        targetSize.width,
                        targetSize.height,
                      ),
                    ),
                  ),
                ),
              ),

              // tooltip at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildTooltipContent(context, step),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipContent(BuildContext context, TutorialStep step) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipMaxWidth = screenSize.width - 32;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: tooltipMaxWidth,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.titleKey.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.descriptionKey.tr,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color:
                        index == currentStep
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect targetRect;

  SpotlightPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

    // circular spotlight center
    final center = Offset(
      targetRect.left + targetRect.width / 2,
      targetRect.top + targetRect.height / 2,
    );

    final radius =
        (targetRect.width > targetRect.height
                ? targetRect.width
                : targetRect.height) /
            2 +
        12;

    // min radius safety
    final safeRadius = radius < 24.0 ? 24.0 : radius;

    // evenodd path for cutout
    final path =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addOval(Rect.fromCircle(center: center, radius: safeRadius));

    canvas.drawPath(path, overlayPaint);

    // dashed border
    _drawDashedCircle(
      canvas,
      center,
      safeRadius,
      dashWidth: 8,
      dashSpace: 4,
      color: Colors.white.withValues(alpha: 0.9),
      strokeWidth: 3,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius, {
    required double dashWidth,
    required double dashSpace,
    required Color color,
    required double strokeWidth,
  }) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final totalCircumference = 2 * 3.14159 * radius;
    final dashCount = (totalCircumference / (dashWidth + dashSpace)).floor();
    final actualDashWidth = (totalCircumference / dashCount) - dashSpace;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (actualDashWidth + dashSpace) / radius);
      final sweepAngle = actualDashWidth / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../constant/AppAssets.dart';
import '../constant/AppColor.dart';

class CapsuleMacroGrid extends StatefulWidget {
  const CapsuleMacroGrid({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.onSequenceComplete,
  });

  final num calories;
  final num protein;
  final num carbs;
  final num fats;
  final VoidCallback? onSequenceComplete;

  @override
  State<CapsuleMacroGrid> createState() => _CapsuleMacroGridState();
}

class _CapsuleMacroGridState extends State<CapsuleMacroGrid>
    with TickerProviderStateMixin {
  late List<_CapsuleItem> _items;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _items = [
      _CapsuleItem(
        label: 'Calorie'.tr,
        color: AppColor.primaryOrange,
        value: widget.calories,
        unit: 'kcal_unit'.tr,
      ),
      _CapsuleItem(
        label: 'Protein'.tr,
        color: AppColor.primaryOrange,
        value: widget.protein,
        unit: 'protein_unit'.tr,
      ),
      _CapsuleItem(
        label: 'Carbs'.tr,
        color: AppColor.primaryOrange,
        value: widget.carbs,
        unit: 'carbs_unit'.tr,
      ),
      _CapsuleItem(
        label: 'Fats'.tr,
        color: AppColor.primaryOrange,
        value: widget.fats,
        unit: 'fat_unit'.tr,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant CapsuleMacroGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // rebuild on prop change
    if (oldWidget.calories != widget.calories ||
        oldWidget.protein != widget.protein ||
        oldWidget.carbs != widget.carbs ||
        oldWidget.fats != widget.fats) {
      setState(() {
        _items = [
          _CapsuleItem(
            label: 'Calorie'.tr,
            color: AppColor.primaryOrange,
            value: widget.calories,
            unit: 'kcal_unit'.tr,
          ),
          _CapsuleItem(
            label: 'Protein'.tr,
            color: AppColor.primaryOrange,
            value: widget.protein,
            unit: 'protein_unit'.tr,
          ),
          _CapsuleItem(
            label: 'Carbs'.tr,
            color: AppColor.primaryOrange,
            value: widget.carbs,
            unit: 'carbs_unit'.tr,
          ),
          _CapsuleItem(
            label: 'Fats'.tr,
            color: AppColor.primaryOrange,
            value: widget.fats,
            unit: 'fat_unit'.tr,
          ),
        ];
        // reset animation
        _hasAnimated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // debug replay button
    final Widget debugButton =
        kDebugMode
            ? Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: IconButton(
                  icon: const Icon(Icons.replay, size: 20),
                  color: AppColor.primaryOrange,
                  tooltip: 'Restart animations (debug)',
                  onPressed: () {
                    // toggle visibility trigger
                    setState(() {
                      _hasAnimated = false;
                    });
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      setState(() {
                        _hasAnimated = true;
                      });
                    });
                  },
                ),
              ),
            )
            : const SizedBox.shrink();

    return Stack(
      children: [
        VisibilityDetector(
          key: const Key('capsule-macro-grid'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction >= 0.5 && !_hasAnimated) {
              setState(() => _hasAnimated = true);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CapsuleCard(
                  label: item.label,
                  value: item.value,
                  unit: item.unit,
                  color: item.color,
                  delay: Duration.zero,
                  shouldAnimate: _hasAnimated,
                ),
              );
            },
          ),
        ),
        debugButton,
      ],
    );
  }
}

class _CapsuleItem {
  final String label;
  final Color color;
  final num value;
  final String unit;
  _CapsuleItem({
    required this.label,
    required this.color,
    required this.value,
    required this.unit,
  });
}

class _CapsuleCard extends StatefulWidget {
  const _CapsuleCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.delay,
    required this.shouldAnimate,
  });

  final String label;
  final num value;
  final String unit;
  final Color color;
  final Duration delay;
  final bool shouldAnimate; // whether to trigger animations based on scroll

  @override
  State<_CapsuleCard> createState() => _CapsuleCardState();
}

class _CapsuleCardState extends State<_CapsuleCard>
    with TickerProviderStateMixin {
  late final AnimationController _lottie;
  late final AnimationController _number;
  late final AnimationController _breath;
  late final AnimationController _drop;
  late final Animation<double> _breathScale;
  late final Animation<double> _dropOffset;
  bool _numberStarted = false;
  // Reveal threshold for number during Lottie playback
  static const double _revealThreshold = 0.65;

  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _lottie = AnimationController(vsync: this);
    _number = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _drop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _breathScale = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut));

    // drop animation
    _dropOffset = Tween<double>(
      begin: -80.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _drop, curve: Curves.bounceOut));
  }

  @override
  void didUpdateWidget(covariant _CapsuleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // trigger on animate
    if (!oldWidget.shouldAnimate && widget.shouldAnimate) {
      Future.delayed(widget.delay, _play);
    }
    // reset on data change
    if (oldWidget.value != widget.value ||
        oldWidget.label != widget.label ||
        oldWidget.unit != widget.unit) {
      // reset and replay
      _breath.stop();
      if (widget.shouldAnimate) {
        _play();
      }
    }
  }

  void _play() async {
    if (!mounted) return;
    setState(() => _opened = false);
    _numberStarted = false;
    _number.reset();
    try {
      _lottie.reset();
      // play lottie
      _lottie.forward(from: 0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _lottie.dispose();
    _number.dispose();
    _breath.dispose();
    _drop.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lottie.addListener(() {
      if (!_numberStarted &&
          _lottie.duration != null &&
          _lottie.value >= _revealThreshold) {
        _numberStarted = true;
        if (mounted) setState(() => _opened = true);
        _number.forward(from: 0);
        _drop.forward(from: 0);
        // start breathing
        if (!_breath.isAnimating) _breath.repeat(reverse: true);
      }
    });
    _lottie.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // keep breathing
        if (!_breath.isAnimating) _breath.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // asset icon
    String assetIcon;
    switch (widget.label.toLowerCase()) {
      case 'calorie':
      case 'calories':
        assetIcon = AppAssets.calorie;
        break;
      case 'protein':
        assetIcon = AppAssets.protein;
        break;
      case 'carbs':
      case 'carbohydrates':
        assetIcon = AppAssets.carb;
        break;
      case 'fats':
      case 'fat':
        assetIcon = AppAssets.fat;
        break;
      default:
        assetIcon = AppAssets.ai;
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColor.darkCard
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Theme.of(context).brightness == Brightness.dark
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // nutrition icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(assetIcon, width: 24, height: 24),
            ),
          ),
          const SizedBox(width: 16),
          // label
          Expanded(
            flex: 2,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // capsule and number
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // capsule animation
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ScaleTransition(
                    scale: _breathScale,
                    child: Lottie.asset(
                      AppAssets.capsule,
                      controller: _lottie,
                      onLoaded: (comp) {
                        _lottie.duration = comp.duration;
                      },
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // animated number
                AnimatedBuilder(
                  animation: _drop,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _dropOffset.value),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _opened ? 1 : 0,
                        child: _AnimatedCounter(
                          controller: _number,
                          target: widget.value,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColor.primaryOrange,
                            fontSize:
                                (Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.fontSize ??
                                    22) +
                                4,
                          ),
                          unit: widget.unit,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({
    required this.controller,
    required this.target,
    required this.style,
    required this.unit,
  });
  final AnimationController controller;
  final num target;
  final TextStyle? style;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final progress = (controller.value).clamp(0.0, 1.0);
        final current = target.toDouble() * progress;
        bool isInteger = current % 1 == 0;

        String text;
        if (unit.contains('kcal') || unit == 'kcal_unit'.tr) {
          text = '${current.round()} $unit';
        } else {
          text = '${current.toStringAsFixed(1)} $unit';
        }

        return Text(text, style: style);
      },
    );
  }
}

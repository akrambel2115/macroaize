import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomModePicker extends StatefulWidget {
  final List<String> items;
  final List<String> icons;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const BottomModePicker({
    super.key,
    required this.items,
    this.icons = const [],
    required this.currentIndex,
    required this.onChanged,
    this.height = 64,
  });

  @override
  State<BottomModePicker> createState() => _BottomModePickerState();
}

class _BottomModePickerState extends State<BottomModePicker> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: 0.3,
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOut));

    // delay for layout
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
  _pageController.dispose();
  _entranceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BottomModePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _pageController.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: widget.height,
              constraints: const BoxConstraints(maxWidth: 400),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: widget.onChanged,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;

                      if (_pageController.hasClients && _pageController.position.haveDimensions) {
                        final page = _pageController.page ?? widget.currentIndex.toDouble();
                        value = (1.0 - ((page - index).abs() * 0.5)).clamp(0.0, 1.0);
                      }

                      // scale and opacity
                      final scale = 0.7 + (value * 0.3);
                      final opacity = 0.4 + (value * 0.6);
                      final isCenter = (index == widget.currentIndex);

                      return Transform.scale(
                        scale: scale,
                        child: Center(
                          child: Opacity(
                            opacity: opacity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                widget.items[index].tr,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: isCenter ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: isCenter ? 14 : 12,
                                    ) ?? const TextStyle(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

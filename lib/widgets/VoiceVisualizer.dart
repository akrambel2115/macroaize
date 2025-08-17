import 'package:flutter/material.dart';

class VoiceVisualizer extends StatefulWidget {
  final double level; // expected 0.0 - ~1.0 (or speech package's native range)
  final double width;
  final double height;
  final Color color;

  const VoiceVisualizer({Key? key, required this.level, this.width = 40, this.height = 40, this.color = Colors.black}) : super(key: key);

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late double _displayLevel;

  @override
  void initState() {
    super.initState();
    _displayLevel = widget.level;
  }

  @override
  void didUpdateWidget(covariant VoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smooth the level change
    _displayLevel = widget.level;
  }

  @override
  Widget build(BuildContext context) {
    final bars = 5;
    final spacing = 2.0;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars, (i) {
          final t = (i + 1) / bars; // distribute heights
          final base = (widget.height / 4) + (widget.height * 0.6 * (widget.level * t));
          final barHeight = base.clamp(2.0, widget.height);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: (widget.width - (bars - 1) * spacing) / bars,
              height: barHeight,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

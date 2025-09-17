import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';

class WorkoutSelectorRadial extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool showMicrocopy;

  const WorkoutSelectorRadial({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.showMicrocopy = true,
  });

  @override
  Widget build(BuildContext context) {
    Alignment pos(String id) {
      if (selectedId == id) return Alignment.center;
      switch (id) {
        case '0-2':
          return const Alignment(0, -0.9); // top center
        case '3-5':
          return const Alignment(-0.8, 0.6); // bottom left
        case '6+':
          return const Alignment(0.8, 0.6); // bottom right
        default:
          return Alignment.center;
      }
    }

    Widget circle({
      required String id,
      required List<Color> gradient,
    }) {
    final isSelected = selectedId == id;
    final hasSelection = selectedId.isNotEmpty;
    final scale = isSelected ? 1.15 : (hasSelection ? 0.85 : 1.0);
    final String indexLabel = id == '0-2' ? '0-1' : id == '3-5' ? '2-4' : '+5';

      return AnimatedAlign(
        alignment: pos(id),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          scale: scale,
          child: GestureDetector(
            onTap: () => onSelect(id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 126,
                  height: 126,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          id == '0-2'
                              ? 'assets/icons/lazy.png'
                              : id == '3-5'
                                  ? 'assets/icons/moderate.png'
                                  : 'assets/icons/advanced.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColor.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    indexLabel,
                    style: TextStyle(
                      color: AppColor.primaryOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget wheel() => SizedBox(
          height: 320,
          child: Stack(
            fit: StackFit.expand,
            children: [
              circle(
                id: '0-2',
                gradient: const [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              circle(
                id: '3-5',
                gradient: [AppColor.primaryOrange, Colors.deepOrangeAccent],
              ),
              circle(
                id: '6+',
                gradient: const [Colors.green, Colors.lightGreenAccent],
              ),
              
            ],
          ),
        );

    Widget microcopy() {
      String emoji = '';
      String keyText = '';
      switch (selectedId) {
        case '0-2':
          keyText = 'Workout Now and then';
          break;
        case '3-5':
          keyText = 'A few workout per week';
          break;
        case '6+':
          keyText = 'Dedicated athlete';
          break;
      }
      if (selectedId.isEmpty) return const SizedBox.shrink();
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              keyText.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ) ?? TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        wheel(),
        if (showMicrocopy) const SizedBox(height: 16),
        if (showMicrocopy) microcopy(),
      ],
    );
  }
}

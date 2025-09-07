import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class GoalAndWeightPicker extends StatelessWidget {
  final String selectedGoal; // "Gain Weight" or "Lose Weight" or ''
  final ValueChanged<String> onSelectGoal;
  final int minKg;
  final int count;
  final ValueChanged<int> onDesiredWeightChanged;

  const GoalAndWeightPicker({
    super.key,
    required this.selectedGoal,
    required this.onSelectGoal,
    required this.onDesiredWeightChanged,
    this.minKg = 50,
    this.count = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SplitGoalCard(
          selectedGoal: selectedGoal,
          onSelectGoal: onSelectGoal,
        ).paddingOnly(bottom: 16, top: 12),
        Text(
          'Choose your desired weight?'.tr,
          style: Theme.of(context).textTheme.headlineLarge,
        ).paddingOnly(top: 20, bottom: 10),
        Text(
          selectedGoal,
          style: Theme.of(context).textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 10),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : AppColor.darkCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CupertinoPicker(
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              onDesiredWeightChanged(minKg + index);
            },
            children: List.generate(count, (index) {
              return Center(
                child: Text(
                  '${minKg + index} ${'kg'.tr}',
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SplitGoalCard extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onSelectGoal;

  const _SplitGoalCard({
    required this.selectedGoal,
    required this.onSelectGoal,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGain = selectedGoal == 'Gain Weight';
    final bool isLose = selectedGoal == 'Lose Weight';
    final bool hasSel = selectedGoal.isNotEmpty;

    // Further reduce heights to avoid scrolling on most devices
    final double topH = hasSel ? (isGain ? 120 : 60) : 80;
    final double botH = hasSel ? (isLose ? 120 : 60) : 80;
    // animations use individual curves per widget

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Diagonal divider
            IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: -0.785398, // -45 degrees
                  child: Container(
                    width: 2,
                    // make divider height exactly match the two tiles so the
                    // Stack doesn't leave extra space under the lower tile
                    height: topH + botH,
                    color: Colors.white.withOpacity(
                      Theme.of(context).brightness == Brightness.light
                          ? 0.5
                          : 0.2,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HalfTile(
                  height: topH,
                  label: 'Gain Weight'.tr,
                  icon: Icons.arrow_upward_rounded,
                  assetIcon: 'assets/icons/gain.png',
                  gradient: const [
                    AppColor.primaryOrange,
                    Colors.deepOrangeAccent,
                  ],
                  selected: isGain,
                  onTap: () => onSelectGoal('Gain Weight'),
                ),
                _HalfTile(
                  height: botH,
                  label: 'Lose Weight'.tr,
                  icon: Icons.arrow_downward_rounded,
                  assetIcon: 'assets/icons/loose.png',
                  gradient: const [Colors.blueAccent, Colors.teal],
                  selected: isLose,
                  onTap: () => onSelectGoal('Lose Weight'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HalfTile extends StatelessWidget {
  final double height;
  final String label;
  final IconData icon;
  final String? assetIcon;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  const _HalfTile({
    required this.height,
    required this.label,
    required this.icon,
    this.assetIcon,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final curve = Curves.easeInOutCubic;
    return AnimatedOpacity(
      opacity: selected || !selected ? (selected ? 1.0 : 0.6) : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: curve,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: curve,
        height: height,
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      selected
                          ? gradient
                          : gradient.map((c) => c.withOpacity(0.8)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Prefer explicit assetIcon if provided (avoids matching localized labels)
                      if (assetIcon != null)
                        Image.asset(assetIcon!, width: 28, height: 28)
                      else
                        Icon(icon, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

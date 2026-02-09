import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
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

class _CapsuleMacroGridState extends State<CapsuleMacroGrid> {
  late List<_CapsuleItem> _items;

  @override
  void initState() {
    super.initState();
    _updateItems();
  }

  @override
  void didUpdateWidget(covariant CapsuleMacroGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calories != widget.calories ||
        oldWidget.protein != widget.protein ||
        oldWidget.carbs != widget.carbs ||
        oldWidget.fats != widget.fats) {
      setState(() {
        _updateItems();
      });
    }
  }

  void _updateItems() {
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
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _CapsuleCard(
          label: item.label,
          value: item.value,
          unit: item.unit,
          color: item.color,
        );
      },
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

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final num value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // asset icon
    String assetIcon;
    switch (label.toLowerCase()) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(assetIcon, width: 24, height: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatValue(value, unit),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColor.primaryOrange,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(num value, String unit) {
    if (unit.contains('kcal') || unit == 'kcal_unit'.tr) {
      return '${value.round()} $unit';
    } else {
      return '${value.toStringAsFixed(1)} $unit';
    }
  }
}

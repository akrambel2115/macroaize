import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class SharedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  const SharedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
  this.hint = '',
  this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    bool hasText = false;
    try {
      hasText = controller.text.isNotEmpty;
    } catch (_) {
      hasText = false;
    }
    final isDark = context.theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColor.neutralGrey800 : AppColor.neutralGrey200.withOpacity(0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.search_rounded,
              color: AppColor.neutralGrey500,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColor.neutralGrey900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.textTheme.bodyLarge?.copyWith(
                  color: AppColor.neutralGrey500,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.clear_rounded,
                color: AppColor.neutralGrey500,
                size: 20,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

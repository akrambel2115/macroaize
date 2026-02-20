import 'package:flutter/material.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:macroaize/widgets/modern_button.dart';

class StoppingGoalView extends StatefulWidget {
  const StoppingGoalView({super.key});

  @override
  State<StoppingGoalView> createState() => _StoppingGoalViewState();
}

class _StoppingGoalViewState extends State<StoppingGoalView> {
  final ScrollController _scrollController = ScrollController();
  bool _hasInteracted = false;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _startPeekAnimation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startPeekAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    while (mounted && !_hasInteracted) {
      _isProgrammaticScroll = true;

      // Peek right
      await _scrollController.animateTo(
        60.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );

      if (!mounted || _hasInteracted) return;

      // Peek back left
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );

      _isProgrammaticScroll = false;

      if (!mounted || _hasInteracted) return;

      // Small pause before repeating
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's stopping you from reaching your goals?".tr,
              style: context.theme.textTheme.headlineLarge,
            ).paddingOnly(top: 20, bottom: 16),

            // Horizontal scrollable chips
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification &&
                    !_isProgrammaticScroll) {
                  _hasInteracted = true;
                }
                return false;
              },
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 5, // We'll use the items list inside
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final items = <Map<String, dynamic>>[
                      {
                        "label": "Lack of consistency".tr,
                        "icon": Icons.schedule,
                      },
                      {
                        "label": "Unhealthy eating habits".tr,
                        "icon": Icons.restaurant,
                      },
                      {"label": "Lack of supports".tr, "icon": Icons.group_off},
                      {
                        "label": "Busy schedule".tr,
                        "icon": Icons.calendar_month,
                      },
                      {
                        "label": "Lack of meal inspiration".tr,
                        "icon": Icons.lightbulb,
                      },
                    ];
                    final label = items[index]['label'] as String;
                    final icon = items[index]['icon'] as IconData;
                    final bool selected =
                        controller.selectedStoppingGoal == label;
                    return GestureDetector(
                      onTap: () {
                        _hasInteracted = true;
                        controller.onChangeStoppingGoal(label);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 16 : 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              selected
                                  ? AppColor.primaryGradient
                                  : LinearGradient(
                                    colors: [
                                      context.theme.cardColor,
                                      context.theme.cardColor,
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(28),
                          border:
                              selected
                                  ? Border.all(color: Colors.transparent)
                                  : Border.all(
                                    color: context.theme.dividerColor
                                        .withValues(alpha: 0.4),
                                  ),
                          boxShadow:
                              selected
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [
                                    const BoxShadow(
                                      color: Colors.transparent,
                                      blurRadius: 0,
                                      offset: Offset.zero,
                                    ),
                                  ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color:
                                  selected
                                      ? Colors.white
                                      : context.theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 260),
                              style: context.theme.textTheme.titleSmall!
                                  .copyWith(
                                    color:
                                        selected
                                            ? Colors.white
                                            : context
                                                .theme
                                                .textTheme
                                                .titleSmall!
                                                .color,
                                    fontWeight:
                                        selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                  ),
                              child: Text(label),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),
            // Lottie display
            Expanded(
              child: Center(
                child:
                    (() {
                      final items = <Map<String, dynamic>>[
                        {
                          "label": "Lack of consistency".tr,
                          "asset": 'assets/lottie/inconsistence.json',
                        },
                        {
                          "label": "Unhealthy eating habits".tr,
                          "asset": 'assets/lottie/unhealthy.json',
                        },
                        {
                          "label": "Lack of supports".tr,
                          "asset": 'assets/lottie/lackSupport.json',
                        },
                        {
                          "label": "Busy schedule".tr,
                          "asset": 'assets/lottie/busy.json',
                        },
                        {
                          "label": "Lack of meal inspiration".tr,
                          "asset": 'assets/lottie/lackInspiration.json',
                        },
                      ];
                      final sel = controller.selectedStoppingGoal;
                      final matched =
                          sel.isNotEmpty
                              ? items.firstWhere(
                                (it) => it['label'] == sel,
                                orElse: () => {},
                              )
                              : {};
                      final asset =
                          matched.isNotEmpty
                              ? matched['asset'] as String
                              : null;
                      return asset == null
                          ? const SizedBox.shrink()
                          : SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Lottie.asset(asset, repeat: true),
                              ),
                            ),
                          );
                    })(),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'Previous'.tr,
                    onPressed: () {
                      _hasInteracted = true;
                      controller.selectedView = 4;
                      controller.update();
                    },
                    style: ModernButtonStyle.secondary,
                    size: ModernButtonSize.medium,
                    borderRadius: BorderRadius.circular(30),
                    height: 50,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ModernButton(
                    text: "Continue".tr,
                    onPressed:
                        controller.selectedStoppingGoal.isNotEmpty
                            ? () {
                              _hasInteracted = true;
                              controller.onChangeView();
                            }
                            : null,
                    style: ModernButtonStyle.primary,
                    size: ModernButtonSize.medium,
                    borderRadius: BorderRadius.circular(30),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                    height: 50,
                  ),
                ),
              ],
            ).paddingOnly(top: 30),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:get/get.dart';

class PlanReviewView extends GetView<SignUpController> {
  const PlanReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back button on this screen
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Your Plan is Ready!'.tr,
                      textAlign: TextAlign.center,
                      style: context.theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We have customized your nutrition plan based on your goals'
                          .tr,
                      textAlign: TextAlign.center,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutralGrey600,
                      ),
                    ),
                  ],
                ),
              ),

              // Plan Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Obx(
                    () => Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Image.asset(
                              'assets/icons/calorie.png',
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              'Calorie Goal'.tr,
                              style: context.theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              controller.calculatedCalories.value.toString(),
                              style: context.theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppColor.neutralWhite,
                              ),
                            ),
                            onTap:
                                () => _showEditDialog(
                                  context,
                                  'Update Calorie Goal'.tr,
                                  controller.calculatedCalories.value,
                                  (value) {
                                    controller.calculatedCalories.value = value;
                                    controller.update();
                                  },
                                ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey700
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Image.asset(
                              'assets/icons/protein.png',
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              'Protein goal'.tr,
                              style: context.theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              controller.calculatedProtein.value.toString(),
                              style: context.theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppColor.neutralWhite,
                              ),
                            ),
                            onTap:
                                () => _showEditDialog(
                                  context,
                                  'Update Protein Goal'.tr,
                                  controller.calculatedProtein.value,
                                  (value) {
                                    controller.calculatedProtein.value = value;
                                    controller.update();
                                  },
                                ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey700
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Image.asset(
                              'assets/icons/carb.png',
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              'Carb goal'.tr,
                              style: context.theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              controller.calculatedCarbs.value.toString(),
                              style: context.theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppColor.neutralWhite,
                              ),
                            ),
                            onTap:
                                () => _showEditDialog(
                                  context,
                                  'Update Carb Goal'.tr,
                                  controller.calculatedCarbs.value,
                                  (value) {
                                    controller.calculatedCarbs.value = value;
                                    controller.update();
                                  },
                                ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey700
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Image.asset(
                              'assets/icons/fat.png',
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              'Fat goal'.tr,
                              style: context.theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              controller.calculatedFat.value.toString(),
                              style: context.theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppColor.neutralWhite,
                              ),
                            ),
                            onTap:
                                () => _showEditDialog(
                                  context,
                                  'Update Fat Goal'.tr,
                                  controller.calculatedFat.value,
                                  (value) {
                                    controller.calculatedFat.value = value;
                                    controller.update();
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Continue Button
              Container(
                padding: const EdgeInsets.all(20),
                child: ModernButton(
                  text: 'Continue to Premium'.tr,
                  onPressed: () {
                    controller.navigateToPremium();
                  },
                  style: ModernButtonStyle.primary,
                  size: ModernButtonSize.large,
                  borderRadius: BorderRadius.circular(30),
                  height: 56,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    int currentValue,
    Function(int) onUpdate,
  ) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: context.theme.cardColor,
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'Enter value'.tr),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  final value =
                      int.tryParse(controller.text.trim()) ?? currentValue;
                  onUpdate(value);
                  Navigator.of(ctx).pop();
                },
                child: Text('save'.tr),
              ),
            ],
          ),
    );
  }
}

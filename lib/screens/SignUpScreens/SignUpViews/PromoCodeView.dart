import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:foodcalorietracker/shared/services/influencer_service.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class PromoCodeView extends GetView<SignUpController> {
  const PromoCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    final promoController = TextEditingController();
    final influencerService = InfluencerService();

    return StatefulBuilder(
      builder: (context, setState) {
        bool isValidating = false;
        String? errorMessage;
        bool isValid = false;

        Future<void> validatePromo() async {
          final code = promoController.text.toUpperCase().trim();
          if (code.isEmpty) {
            setState(() {
              errorMessage = 'Please enter a promo code';
            });
            return;
          }

          setState(() {
            isValidating = true;
            errorMessage = null;
          });

          try {
            final result = await influencerService.validatePromoCode(code);
            if (result.valid) {
              setState(() {
                isValid = true;
                isValidating = false;
                errorMessage = null;
              });
              // Save promo code to controller
              controller.promoCode = code;
              controller.update();
            } else {
              setState(() {
                isValidating = false;
                errorMessage = 'Invalid promo code';
              });
            }
          } catch (e) {
            setState(() {
              isValidating = false;
              errorMessage = 'Invalid promo code';
            });
          }
        }

        return Column(
          children: [
            // Title at top
            Text(
              'Have a Promo Code?'.tr,
              textAlign: TextAlign.center,
              style: context.theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).paddingOnly(top: 20),

            // Center content with flexible spacing
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Enter your promo code to get 3 days free trial'.tr,
                        textAlign: TextAlign.center,
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: AppColor.neutralGrey600,
                        ),
                      ).paddingSymmetric(horizontal: 20),

                      const SizedBox(height: 40),

                      // Promo code input
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: context.theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                errorMessage != null
                                    ? Colors.red.withOpacity(0.5)
                                    : isValid
                                    ? Colors.green.withOpacity(0.5)
                                    : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: promoController,
                          style: TextStyle(
                            color: context.theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ENTER CODE'.tr,
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon:
                                isValid
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : null,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          onChanged: (value) {
                            if (errorMessage != null || isValid) {
                              setState(() {
                                errorMessage = null;
                                isValid = false;
                              });
                            }
                          },
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],

                      if (isValid) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Promo code applied successfully!'.tr,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Validate button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ModernButton(
                          text: 'Validate Code'.tr,
                          onPressed: isValidating ? null : validatePromo,
                          style: ModernButtonStyle.secondary,
                          size: ModernButtonSize.medium,
                          borderRadius: BorderRadius.circular(30),
                          height: 50,
                          icon:
                              isValidating
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons at bottom
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'Previous'.tr,
                    onPressed: () {
                      controller.selectedView =
                          5; // Go back to StoppingGoalView
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
                    text: 'Continue'.tr,
                    onPressed: () => controller.onChangeView(),
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
            ).paddingOnly(bottom: 20, left: 20, right: 20),
          ],
        );
      },
    );
  }
}

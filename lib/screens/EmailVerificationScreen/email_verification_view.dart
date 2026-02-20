import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../constant/app_color.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/animated_background.dart';
import 'email_verification_controller.dart';

class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            const AnimatedBackground(),
            // Main content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Top section with title
                    Text(
                      'email_verification_title'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Get.isDarkMode ? Colors.white : AppColor.neutralGrey900,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Lottie animation
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        'assets/lottie/email.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'email_verification_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Get.isDarkMode ? Colors.white : AppColor.neutralGrey900,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        Obx(
                          () => Text(
                            'email_sent_to'.trParams({
                              'email': controller.userEmail.value,
                            }),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColor.neutralGrey600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'email_verification_instructions'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColor.neutralGrey600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Verification status indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode ? AppColor.darkCard : AppColor.neutralGrey50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColor.primaryOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.primaryOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'checking_verification_status'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Get.isDarkMode
                                        ? AppColor.darkTextSecondary
                                        : AppColor.neutralGrey600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Bottom buttons
                    Column(
                      children: [
                        // Resend button
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child:
                                controller.canResend
                                    ? ModernButton(
                                          text: 'resend_verification_email'.tr,
                                          loading: controller.isResendLoading.value,
                                          onPressed:
                                              controller.resendVerificationEmail,
                                          style: ModernButtonStyle.primary,
                                          size: ModernButtonSize.large,
                                          borderRadius: BorderRadius.circular(20),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        )
                                        : ModernButton(
                                          text:
                                              controller
                                                          .cooldownRemaining
                                                          .inSeconds >
                                                      0
                                                  ? 'resend_cooldown'.trParams({
                                                    'seconds':
                                                        controller
                                                            .cooldownRemaining
                                                            .inSeconds
                                                            .toString(),
                                                  })
                                                  : 'resend_limit_reached'
                                                      .trParams({
                                                        'attempts':
                                                            controller
                                                                .remainingAttempts
                                                                .toString(),
                                                      }),
                                          onPressed: null,
                                          style: ModernButtonStyle.outline,
                                          size: ModernButtonSize.large,
                                          disabled: true,
                                          borderRadius: BorderRadius.circular(20),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Help text
                        Obx(
                          () => Text(
                            'verification_attempts_remaining'.trParams({
                              'remaining':
                                  controller.remainingAttempts.toString(),
                              'total':
                                  EmailVerificationController.maxResendAttempts
                                      .toString(),
                            }),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.neutralGrey600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Skip button
                        TextButton(
                          onPressed: controller.skipVerification,
                          child: Text(
                            'skip_verification'.tr,
                            style: const TextStyle(
                              color: AppColor.neutralGrey600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

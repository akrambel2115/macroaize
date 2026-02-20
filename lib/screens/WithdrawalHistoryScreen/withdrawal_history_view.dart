import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:macroaize/shared/models/influencer.dart';
import 'withdrawal_history_controller.dart';

class WithdrawalHistoryView extends GetView<WithdrawalHistoryController> {
  const WithdrawalHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: GetBuilder<WithdrawalHistoryController>(
        builder: (controller) {
          if (controller.isLoading) {
            return _buildLoadingState(context);
          }

          if (controller.withdrawalHistory.isNotEmpty) {
            return _buildHistoryList(context, controller);
          } else {
            return _buildEmptyState(context);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.theme.primaryColor,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'withdrawal_history'.tr,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.theme.primaryColor,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: context.theme.primaryColor),
          onPressed: () => controller.refreshHistory(),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading withdrawal history...'.tr,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColor.neutralGrey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WithdrawalHistoryController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.refreshHistory,
      color: AppColor.primaryOrange,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.withdrawalHistory.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final withdrawal = controller.withdrawalHistory[index];
          return _buildWithdrawalHistoryItem(context, withdrawal);
        },
      ),
    );
  }

  Widget _buildWithdrawalHistoryItem(
    BuildContext context,
    WithdrawalRecord withdrawal,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (withdrawal.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColor.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'processing':
        statusColor = AppColor.warning;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'failed':
        statusColor = AppColor.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColor.neutralGrey600;
        statusIcon = Icons.help_outline_rounded;
    }

    return ModernFadeSlideTransition(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutralGrey700
                    : AppColor.neutralGrey200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.neutralGrey900.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${withdrawal.amount.toStringAsFixed(0)} ${'currency_dzd'.tr}',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryOrange,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _localizedStatus(
                          withdrawal.status,
                          withdrawal.statusDisplay,
                        ),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Details
            _buildDetailRow(
              context,
              'request_id_short'.tr,
              withdrawal.id,
              Icons.receipt_long_rounded,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              context,
              'bank_account_short'.tr,
              withdrawal.ripMasked,
              Icons.account_balance_rounded,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              context,
              'requested_date'.tr,
              withdrawal.requestedAt != null
                  ? _formatDate(withdrawal.requestedAt!)
                  : 'unknown_date'.tr,
              Icons.calendar_today_rounded,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              context,
              'processing_date'.tr,
              (withdrawal.estimatedProcessingDate != null &&
                      withdrawal.estimatedProcessingDate!.isNotEmpty)
                  ? _formatDateString(withdrawal.estimatedProcessingDate!)
                  : 'unknown_date'.tr,
              Icons.schedule_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColor.neutralGrey500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColor.neutralGrey600,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              color:
                  context.theme.brightness == Brightness.dark
                      ? AppColor.neutralGrey300
                      : AppColor.neutralGrey800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: ModernFadeSlideTransition(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'no_withdrawal_history'.tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.neutralGrey800,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'withdrawal_history_empty_description'.tr,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              ModernButton(
                text: 'Back to Settings'.tr,
                onPressed: () => Get.back(),
                style: ModernButtonStyle.primary,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format date as dd-MM-yyyy
    String two(int n) => n.toString().padLeft(2, '0');
    final d = two(date.day);
    final m = two(date.month);
    final y = date.year.toString();
    return '$d-$m-$y';
  }

  String _formatDateString(String dateStr) {
    // Parse various date string formats and return dd-MM-yyyy
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return _formatDate(parsed.toLocal());
      // Fallback: if it contains a 'T', take date portion yyyy-mm-dd and reformat
      if (dateStr.contains('T')) {
        final dateOnly = dateStr.split('T').first;
        final parts = dateOnly.split('-');
        if (parts.length >= 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      // Fallback: if already yyyy-mm-dd
      final parts = dateStr.split('-');
      if (parts.length >= 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (_) {}
    // If parsing fails, return original string
    return dateStr;
  }

  // ignore: unused_element
  String _maskRip(String rip) {
    if (rip.isEmpty) return '';
    if (rip.length <= 4) return rip;
    // Mask all but last 4 digits
    final lastFour = rip.substring(rip.length - 4);
    final masked = '*' * (rip.length - 4);
    return '$masked$lastFour';
  }

  String _localizedStatus(String status, String fallback) {
    final s = status.toLowerCase();
    if (s == 'processing') return 'processing'.tr;
    if (s == 'completed') return 'completed'.tr;
    if (s == 'failed') return 'failed'.tr;
    return fallback;
  }
}

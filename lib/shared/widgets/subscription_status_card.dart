import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:macroaize/constant/app_color.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({super.key, required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMMd();
    final startDate = subscription.startDate;
    DateTime? endDate = subscription.endDate;

    // UI guard to avoid identical from/to dates when provider sends bad or missing expiration
    if (startDate != null && (endDate == null || !endDate.isAfter(startDate))) {
      final isYearly = subscription.planType == 'yearly';
      endDate = isYearly
          ? DateTime.utc(
              startDate.year + 1,
              startDate.month,
              startDate.day,
              startDate.hour,
              startDate.minute,
              startDate.second,
            )
          : DateTime.utc(
              startDate.year,
              startDate.month + 1,
              startDate.day,
              startDate.hour,
              startDate.minute,
              startDate.second,
            );
    }

    final start =
        startDate != null ? fmt.format(startDate.toLocal()) : '-';
    final end = endDate != null ? fmt.format(endDate.toLocal()) : '-';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.success, AppColor.success.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.success.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan: ${subscription.planType ?? '—'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From $start to $end',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

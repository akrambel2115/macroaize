import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({super.key, required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMMd();
    final start =
        subscription.startDate != null
            ? fmt.format(subscription.startDate!.toLocal())
            : '-';
    final end =
        subscription.endDate != null
            ? fmt.format(subscription.endDate!.toLocal())
            : '-';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.success, AppColor.success.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.success.withOpacity(0.25),
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
              color: Colors.white.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From $start to $end',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
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

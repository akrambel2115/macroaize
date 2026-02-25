import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMMd();
    final startDate = subscription.startDate;
    DateTime? endDate = subscription.endDate;

    // UI-side guard: if end is missing or not after start, derive from plan duration
    if (startDate != null && (endDate == null || !endDate.isAfter(startDate))) {
      final isYearly = subscription.planType == 'yearly';
      endDate =
          isYearly
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

    final start = startDate != null ? fmt.format(startDate.toLocal()) : '-';
    final end = endDate != null ? fmt.format(endDate.toLocal()) : '-';
    final plan = (subscription.planType ?? 'premium').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.success, AppColor.success.withValues(alpha: 0.8)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      'Premium · $plan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From: $start',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: $end',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildManageButtons(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildManageButtons(BuildContext context) {
    final List<Widget> actions = [];

    final provider = (subscription.provider ?? '').toLowerCase();
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (isMobile && provider == 'revenuecat') {
      final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
      final url = Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions';
      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.manage_accounts, color: Colors.white),
          label: Text(
            'Manage on $storeName',
            style: const TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
          ),
        ),
      );
    }

    return actions;
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:foodcalorietracker/shared/services/revenuecat_service.dart';

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
    final plan = (subscription.planType ?? 'premium').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.success, AppColor.success.withOpacity(0.8)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From: $start',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: $end',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
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
    final cfg = Get.find<AppConfigService>();
    final List<Widget> actions = [];

    final provider = (subscription.provider ?? '').toLowerCase();
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (isMobile && provider == 'revenuecat') {
      final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
      final url = Platform.isIOS ? cfg.appStoreUrl : cfg.playStoreUrl;
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

      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            await RevenueCatService().restorePurchases();
          },
          icon: const Icon(Icons.restore, color: Colors.white),
          label: const Text('Restore', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
          ),
        ),
      );
    }

    return actions;
  }
}

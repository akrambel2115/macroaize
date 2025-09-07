// Deprecated: In-app checkout via WebView has been removed.
// Checkout is now handled by opening the system browser externally.
// This placeholder remains to avoid breaking imports in older code paths.

// ignore_for_file: unused_element

import 'package:flutter/widgets.dart';

@Deprecated('Replaced by external browser checkout flow')
class CheckoutWebView extends StatelessWidget {
  const CheckoutWebView({super.key, required this.initialUrl});
  final Uri initialUrl;

  @override
  Widget build(BuildContext context) {
    // Intentionally empty: not used anymore.
    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebView extends StatefulWidget {
  const CheckoutWebView({super.key, required this.initialUrl});
  final Uri initialUrl;

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageFinished: (_) => setState(() => _progress = 100),
          onNavigationRequest: (req) {
            final url = req.url;
            if (kDebugMode) {
              // ignore: avoid_print
              print('[CheckoutWebView] navigation request: $url');
            }
            if (url.contains('status=paid') || url.contains('success=true')) {
              // Delay to ensure any webhook processing completes
              Future.delayed(const Duration(seconds: 2), () {
                Get.back(result: true);
              });
              return NavigationDecision.prevent;
            }
            if (url.contains('status=failed') || url.contains('canceled=true')) {
              Get.back(result: false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.initialUrl);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100)
            LinearProgressIndicator(value: _progress / 100),
        ],
      ),
    );
  }
}

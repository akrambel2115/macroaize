import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class DirectionalTransition extends CustomTransition {
  final Duration duration;
  DirectionalTransition({this.duration = const Duration(milliseconds: 450)});

  bool _isRtl(Locale? locale) {
    if (locale == null) return false;
    final languageCode = locale.languageCode.toLowerCase();
    return ['ar', 'he', 'fa', 'ur'].contains(languageCode);
  }

  @override
  Widget buildTransition(BuildContext context, Curve? curve, Alignment? alignment, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final isRtl = _isRtl(Get.locale ?? Get.deviceLocale);

    final begin = isRtl ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    final end = Offset.zero;
    final tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve ?? Curves.easeInOut));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

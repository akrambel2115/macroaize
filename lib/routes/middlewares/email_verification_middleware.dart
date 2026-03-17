import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/shared/services/email_verification_guard.dart';

class EmailVerificationMiddleware extends GetMiddleware {
  EmailVerificationMiddleware({super.priority = 1});

  final EmailVerificationGuard _guard = EmailVerificationGuard();

  static const Set<String> _publicRoutes = {
    Routes.splashView,
    Routes.welcomeView,
    Routes.transitionView,
    Routes.planIntroView,
    Routes.onBoardingView,
    Routes.signUpView,
    Routes.emailVerificationView,
  };

  @override
  RouteSettings? redirect(String? route) {
    if (route == null || _publicRoutes.contains(route)) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    if (_guard.needsVerificationSync()) {
      return const RouteSettings(name: Routes.emailVerificationView);
    }

    return null;
  }
}

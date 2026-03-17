import 'package:get/get.dart';
import 'package:macroaize/features/auth/data/firebase_auth_repository.dart';
import 'package:macroaize/features/auth/presentation/account_controller.dart';

class AccountDetailsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AccountController>(tag: 'account')) {
      Get.lazyPut<AccountController>(
        () => AccountController(FirebaseAuthRepository()),
        tag: 'account',
      );
    }
  }
}

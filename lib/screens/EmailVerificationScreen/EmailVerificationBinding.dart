import 'package:get/get.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import 'EmailVerificationController.dart';

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmailVerificationController>(
      () => EmailVerificationController(FirebaseAuthRepository()),
    );
  }
}

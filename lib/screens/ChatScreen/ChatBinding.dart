import 'package:foodcalorietracker/screens/ChatScreen/ChatController.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppUserService>()) {
      final svc = AppUserService();
      Get.put<AppUserService>(svc, permanent: true);
      try {
        svc.initialize();
      } catch (_) {}
    }

    Get.lazyPut(() => ChatController());
  }
}

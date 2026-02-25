import 'package:get/get.dart';

/// PremiumController is already registered as a permanent singleton
/// in main.dart via Get.put(PremiumController()). This binding
/// exists for route configuration but does not re-register the controller.
class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    // No-op: PremiumController is permanently registered at app startup
  }
}

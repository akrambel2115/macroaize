import 'package:macroaize/screens/PremiumScreen/PremiumController.dart';
import 'package:get/get.dart';

class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PremiumController());
  }
}

import 'package:foodcalorietracker/screens/PremiumScreen/PremiumController.dart';
import 'package:get/get.dart';

class PremiumBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => PremiumController(),);
  }
}